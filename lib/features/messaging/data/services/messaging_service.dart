import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – MessagingService (messagerie privée anonyme, Firestore temps réel)
// ─────────────────────────────────────────────────────────────────────────────
class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Conversations ──────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getConversations() {
    return _db
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .where('visible', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Future<String> getOrCreateConversation(String otherUid) async {
    final snap = await _db
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .get();
    for (final doc in snap.docs) {
      final parts = List<String>.from(doc.data()['participants'] ?? []);
      if (parts.contains(otherUid)) return doc.id;
    }
    final id = _uuid.v4();
    await _db.collection(AppConstants.colConversations).doc(id).set({
      'id': id, 'participants': [_uid, otherUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': '', 'visible': true,
    });
    return id;
  }

  Future<void> deleteConversation(String convId) async {
    await _db.collection(AppConstants.colConversations)
        .doc(convId).update({'visible': false});
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getMessages(String convId) {
    return _db
        .collection(AppConstants.colMessages)
        .where('conversationId', isEqualTo: convId)
        .where('visible', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendMessage({
    required String convId,
    required String content,
  }) async {
    final msgId = _uuid.v4();
    final batch = _db.batch();
    batch.set(_db.collection(AppConstants.colMessages).doc(msgId), {
      'id': msgId, 'conversationId': convId, 'senderId': _uid,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'visible': true,
    });
    final preview = content.length > 50
        ? '${content.substring(0, 50)}...'
        : content;
    batch.update(_db.collection(AppConstants.colConversations).doc(convId), {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteMessage(String msgId) async {
    final doc = await _db.collection(AppConstants.colMessages).doc(msgId).get();
    if (doc.data()?['senderId'] == _uid) {
      await _db.collection(AppConstants.colMessages)
          .doc(msgId).update({'visible': false});
    }
  }
}
