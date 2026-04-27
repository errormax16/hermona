import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – ForumService (Firestore temps réel)
// ─────────────────────────────────────────────────────────────────────────────
class ForumService {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Posts ──────────────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getPosts({String? category, String sort = 'date'}) {
    Query q = _db
        .collection(AppConstants.colForumPosts)
        .where('visible', isEqualTo: true);
    if (category != null && category != 'Tous') {
      q = q.where('category', isEqualTo: category);
    }
    q = sort == 'popular'
        ? q.orderBy('likesCount', descending: true)
        : q.orderBy('createdAt', descending: true);
    return q.snapshots();
  }

  Future<String> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final id = _uuid.v4();
    await _db.collection(AppConstants.colForumPosts).doc(id).set({
      'id': id, 'title': title, 'content': content,
      'category': category, 'authorId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0, 'repliesCount': 0,
      'reportsCount': 0, 'visible': true,
    });
    return id;
  }

  Future<void> deletePost(String postId) async {
    final doc = await _db.collection(AppConstants.colForumPosts).doc(postId).get();
    if (doc.data()?['authorId'] == _uid) {
      await _db.collection(AppConstants.colForumPosts)
          .doc(postId).update({'visible': false});
    }
  }

  // ── Likes (toggle unique : pas de double like) ─────────────────────────────
  Future<void> toggleLike({
    required String targetId,
    required String targetCollection,
    required String counterField,
  }) async {
    final likeRef = _db.collection(AppConstants.colLikes).doc('${_uid}_$targetId');
    final likeDoc = await likeRef.get();
    final targetRef = _db.collection(targetCollection).doc(targetId);

    if (likeDoc.exists) {
      await likeRef.delete();
      await targetRef.update({counterField: FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'userId': _uid, 'targetId': targetId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await targetRef.update({counterField: FieldValue.increment(1)});
    }
  }

  Future<bool> isLiked(String targetId) async {
    final doc = await _db.collection(AppConstants.colLikes)
        .doc('${_uid}_$targetId').get();
    return doc.exists;
  }

  // ── Réponses ───────────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getReplies(String postId) {
    return _db
        .collection(AppConstants.colForumReplies)
        .where('postId', isEqualTo: postId)
        .where('visible', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> addReply({
    required String postId,
    required String content,
    String? parentReplyId,
  }) async {
    final id = _uuid.v4();
    await _db.collection(AppConstants.colForumReplies).doc(id).set({
      'id': id, 'postId': postId, 'content': content,
      'authorId': _uid, 'parentReplyId': parentReplyId,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0, 'reportsCount': 0, 'visible': true,
    });
    await _db.collection(AppConstants.colForumPosts)
        .doc(postId).update({'repliesCount': FieldValue.increment(1)});
  }

  Future<void> deleteReply(String replyId, String postId) async {
    final doc = await _db.collection(AppConstants.colForumReplies).doc(replyId).get();
    if (doc.data()?['authorId'] == _uid) {
      await _db.collection(AppConstants.colForumReplies)
          .doc(replyId).update({'visible': false});
      await _db.collection(AppConstants.colForumPosts)
          .doc(postId).update({'repliesCount': FieldValue.increment(-1)});
    }
  }

  // ── Signalements (3 signalements = masquage automatique) ──────────────────
  Future<void> reportContent({
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    final reportId  = _uuid.v4();
    final col = targetType == 'post'
        ? AppConstants.colForumPosts
        : AppConstants.colForumReplies;

    await _db.collection(AppConstants.colReports).doc(reportId).set({
      'id': reportId, 'targetId': targetId, 'targetType': targetType,
      'reporterId': _uid, 'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.runTransaction((tx) async {
      final snap  = await tx.get(_db.collection(col).doc(targetId));
      final count = ((snap.data()?['reportsCount'] as int?) ?? 0) + 1;
      tx.update(_db.collection(col).doc(targetId), {
        'reportsCount': count,
        if (count >= 3) 'visible': false,   // masquage automatique
      });
    });
  }
}
