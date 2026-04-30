import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../data/services/messaging_service.dart';

class ChatPrivateScreen extends StatefulWidget {
  final String conversationId;
  const ChatPrivateScreen({super.key, required this.conversationId});
  @override State<ChatPrivateScreen> createState() => _ChatPrivateScreenState();
}

class _ChatPrivateScreenState extends State<ChatPrivateScreen> {
  final _msgCtrl   = TextEditingController();
  final _scrollCtrl= ScrollController();
  final _svc       = MessagingService();
  final _uid       = FirebaseAuth.instance.currentUser?.uid;
  bool _sending    = false;

  @override void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    await _svc.sendMessage(convId: widget.conversationId, content: text);
    _scrollBottom();
    setState(() => _sending = false);
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]), shape: BoxShape.circle),
          child: const Icon(Iconsax.user, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        const Text('Utilisatrice anonyme'),
      ])),
      body: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.warning.withOpacity(0.07),
          child: Row(children: [
            Icon(Iconsax.warning_2, size: 13, color: AppColors.warning),
            const SizedBox(width: 6),
            Expanded(child: Text('Ne partagez aucune information personnelle.', style: TextStyle(color: AppColors.warning, fontSize: 11))),
          ])),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _svc.getMessages(widget.conversationId),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());
            if (docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Iconsax.message_text, size: 48, color: AppTheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Démarrez la conversation !'),
                ])));
            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final d    = docs[i].data() as Map<String, dynamic>;
                final isMe = d['senderId'] == _uid;
                final date = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();
                return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe) Container(margin: const EdgeInsets.only(right: 8), width: 32, height: 32,
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(Iconsax.user, size: 16, color: AppTheme.primary)),
                    Flexible(
                      child: GestureDetector(
                        onLongPress: isMe ? () => _deleteMsg(ctx, docs[i].id) : null,
                        child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isMe ? LinearGradient(colors: [AppTheme.primary, AppColors.secondary]) : null,
                          color: isMe ? null : Theme.of(ctx).cardTheme.color,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16))),
                        child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                          Text(d['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : null, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 3),
                          Text(timeago.format(date, locale: 'fr'),
                              style: TextStyle(color: isMe ? Colors.white.withOpacity(0.65) : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4), fontSize: 10)),
                        ]),
                      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05)),
                    ),
                  ],
                ));
              },
            );
          },
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, maxLines: 4, minLines: 1,
                textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'Message (anonyme)...'))),
            const SizedBox(width: 12),
            GestureDetector(onTap: _send, child: Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]), shape: BoxShape.circle),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Iconsax.send_1, color: Colors.white, size: 20))),
          ]),
        ),
      ]),
    );
  }

  void _deleteMsg(BuildContext ctx, String id) => showModalBottomSheet(context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: Icon(Iconsax.trash, color: AppColors.error), title: const Text('Supprimer ce message'),
        onTap: () async { await _svc.deleteMessage(id); Navigator.pop(ctx); }),
      ListTile(leading: const Icon(Iconsax.close_circle), title: const Text('Annuler'), onTap: () => Navigator.pop(ctx)),
    ])));
}
