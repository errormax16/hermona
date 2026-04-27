import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/forum_service.dart';

class ForumDetailScreen extends StatefulWidget {
  final String postId;
  const ForumDetailScreen({super.key, required this.postId});
  @override State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  final _replyCtrl = TextEditingController();
  final _svc = ForumService();
  String? _replyingToId, _replyingToPreview;
  bool _sending = false;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await _svc.addReply(postId: widget.postId, content: _replyCtrl.text.trim(), parentReplyId: _replyingToId);
    _replyCtrl.clear();
    setState(() { _replyingToId = null; _replyingToPreview = null; _sending = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussion')),
      body: Column(children: [
        Expanded(child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.colForumPosts).doc(widget.postId).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final post = snap.data!.data() as Map<String, dynamic>? ?? {};
            return ListView(padding: const EdgeInsets.all(16), children: [
              FadeInWidget(child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
                    child: Text(post['category'] ?? '', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600))),
                  const Spacer(),
                  if (post['createdAt'] is Timestamp)
                    Text(timeago.format((post['createdAt'] as Timestamp).toDate(), locale: 'fr'),
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11)),
                ]),
                const SizedBox(height: 10),
                Text(post['title'] ?? '', style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(post['content'] ?? '', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6)),
                const SizedBox(height: 14),
                _LikeRow(postId: widget.postId, likes: post['likesCount'] as int? ?? 0, svc: _svc),
              ]))),
              const SizedBox(height: 18),
              Text('Réponses', style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _svc.getReplies(widget.postId),
                builder: (ctx, rSnap) {
                  if (!rSnap.hasData) return const SkeletonCard();
                  final docs = rSnap.data!.docs;
                  final top  = docs.where((d) => (d.data() as Map)['parentReplyId'] == null).toList();
                  final nested = <String, List<QueryDocumentSnapshot>>{};
                  for (final d in docs) {
                    final pid = (d.data() as Map<String, dynamic>)['parentReplyId'];
                    if (pid != null) nested.putIfAbsent(pid, () => []).add(d);
                  }
                  if (top.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24),
                      child: Text('Soyez la première à répondre ! 💬', style: Theme.of(ctx).textTheme.bodySmall)));
                  return Column(children: top.asMap().entries.map((e) => _ReplyCard(
                    data: e.value.data() as Map<String, dynamic>,
                    replyId: e.value.id,
                    nested: nested[e.value.id] ?? [],
                    svc: _svc, postId: widget.postId,
                    onReply: (id, p) => setState(() { _replyingToId = id; _replyingToPreview = p; }),
                    delay: e.key * 60,
                  )).toList());
                },
              ),
              const SizedBox(height: 80),
            ]);
          },
        )),
        if (_replyingToPreview != null) Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.primary.withOpacity(0.07),
          child: Row(children: [
            Icon(Icons.reply, size: 14, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Répondre : $_replyingToPreview', style: TextStyle(fontSize: 12, color: AppTheme.primary), overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() { _replyingToId = null; _replyingToPreview = null; }),
                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24), padding: EdgeInsets.zero),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(children: [
            Expanded(child: TextField(controller: _replyCtrl, maxLines: 3, minLines: 1,
                decoration: const InputDecoration(hintText: 'Votre réponse (anonyme)...'))),
            const SizedBox(width: 12),
            GestureDetector(onTap: _sending ? null : _sendReply,
              child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Iconsax.send_1, color: Colors.white, size: 20))),
          ]),
        ),
      ]),
    );
  }
}

class _LikeRow extends StatefulWidget {
  final String postId; final int likes; final ForumService svc;
  const _LikeRow({required this.postId, required this.likes, required this.svc});
  @override State<_LikeRow> createState() => _LikeRowState();
}
class _LikeRowState extends State<_LikeRow> {
  bool _liked = false;
  @override void initState() { super.initState(); widget.svc.isLiked(widget.postId).then((v) { if (mounted) setState(() => _liked = v); }); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      await widget.svc.toggleLike(targetId: widget.postId, targetCollection: AppConstants.colForumPosts, counterField: 'likesCount');
      setState(() => _liked = !_liked);
    },
    child: Row(children: [
      Icon(_liked ? Iconsax.heart5 : Iconsax.heart, size: 20, color: _liked ? AppColors.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
      const SizedBox(width: 6),
      Text('${widget.likes}', style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _ReplyCard extends StatefulWidget {
  final Map<String, dynamic> data; final String replyId, postId;
  final List<QueryDocumentSnapshot> nested; final ForumService svc;
  final void Function(String, String) onReply; final int delay;
  const _ReplyCard({required this.data, required this.replyId, required this.postId, required this.nested, required this.svc, required this.onReply, required this.delay});
  @override State<_ReplyCard> createState() => _ReplyCardState();
}
class _ReplyCardState extends State<_ReplyCard> {
  bool _liked = false;
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  @override void initState() { super.initState(); widget.svc.isLiked(widget.replyId).then((v) { if (mounted) setState(() => _liked = v); }); }
  @override
  Widget build(BuildContext context) {
    final d     = widget.data;
    final isOwn = d['authorId'] == _uid;
    final date  = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();
    return FadeInWidget(delay: widget.delay, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withOpacity(0.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Iconsax.user, size: 12, color: AppTheme.primary)),
            const SizedBox(width: 8),
            Text('Anonyme', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(timeago.format(date, locale: 'fr'), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Text(d['content'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: () async {
                await widget.svc.toggleLike(targetId: widget.replyId, targetCollection: AppConstants.colForumReplies, counterField: 'likesCount');
                setState(() => _liked = !_liked);
              },
              child: Row(children: [
                Icon(_liked ? Iconsax.heart5 : Iconsax.heart, size: 16, color: _liked ? AppColors.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('${d['likesCount'] ?? 0}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () => widget.onReply(widget.replyId, (d['content'] as String? ?? '').substring(0, (d['content'] as String? ?? '').length.clamp(0, 40))),
              child: Row(children: [Icon(Icons.reply, size: 15, color: AppTheme.primary), const SizedBox(width: 4),
                Text('Répondre', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))]),
            ),
            const Spacer(),
            if (isOwn) GestureDetector(onTap: () async { await widget.svc.deleteReply(widget.replyId, widget.postId); },
              child: Icon(Iconsax.trash, size: 15, color: AppColors.error)),
          ]),
        ])),
      if (widget.nested.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 24, top: 6), child: Column(
        children: widget.nested.map((n) {
          final nd   = n.data() as Map<String, dynamic>;
          final ndt  = nd['createdAt'] is Timestamp ? (nd['createdAt'] as Timestamp).toDate() : DateTime.now();
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.primary.withOpacity(0.1))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.reply, size: 12, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text('Anonyme', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                const Spacer(),
                Text(timeago.format(ndt, locale: 'fr'), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ]),
              const SizedBox(height: 6),
              Text(nd['content'] ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
            ]),
          ));
        }).toList(),
      )),
    ])));
  }
}
