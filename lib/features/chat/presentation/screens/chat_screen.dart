import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/chat_api_service.dart';
import '../../domain/entities/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollCtrl  = ScrollController();
  final _textCtrl    = TextEditingController();
  final _chatSvc     = ChatApiService();
  final _uuid        = const Uuid();
  final List<ChatMessage> _msgs = [];
  bool _loading = false, _typing = false;

  final List<String> _suggestions = [
    'Comment traiter les points noirs ?',
    'Routine pour peau grasse ?',
    'Alimentation anti-acné ?',
    'Acné hormonale – que faire ?',
  ];

  @override
  void initState() { super.initState(); _loadHistory(); }

  @override
  void dispose() { _scrollCtrl.dispose(); _textCtrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { _addWelcome(); return; }
    final hist = await _chatSvc.loadHistory(uid);
    if (hist.isEmpty) { _addWelcome(); return; }
    setState(() => _msgs.addAll(hist));
    _scrollBottom();
  }

  void _addWelcome() => setState(() => _msgs.add(ChatMessage(
    id: _uuid.v4(), role: 'assistant', timestamp: DateTime.now(),
    content: 'Bonjour ! 🌸 Je suis votre assistante beauté AcnéIA.\n\nJe peux vous aider sur :\n• Les types d\'acné et leurs causes\n• Les routines de soins\n• L\'alimentation anti-acné\n• La prévention des poussées\n\nQue souhaitez-vous savoir ? ✨',
  )));

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _textCtrl.clear();
    final uid  = FirebaseAuth.instance.currentUser?.uid;
    final userMsg = ChatMessage(id: _uuid.v4(), role: 'user', content: text, timestamp: DateTime.now());
    setState(() { _msgs.add(userMsg); _loading = true; _typing = true; });
    _scrollBottom();
    if (uid != null) await _chatSvc.saveMessage(userMsg, uid);

    final reply = await _chatSvc.getResponse(history: _msgs, userMessage: text);
    final botMsg = ChatMessage(id: _uuid.v4(), role: 'assistant', content: reply, timestamp: DateTime.now());
    setState(() { _msgs.add(botMsg); _loading = false; _typing = false; });
    if (uid != null) await _chatSvc.saveMessage(botMsg, uid);
    _scrollBottom();
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]),
              shape: BoxShape.circle),
            child: const Text('🤖', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assistante AcnéIA', style: Theme.of(context).textTheme.labelLarge),
            Text(_typing ? 'En train d\'écrire...' : 'En ligne',
                style: TextStyle(fontSize: 11, color: _typing ? AppColors.warning : AppColors.severityNormal)),
          ]),
        ]),
        actions: [IconButton(icon: const Icon(Iconsax.trash), onPressed: _confirmClear)],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: _msgs.length + (_typing ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _msgs.length && _typing) return _TypingDots();
            return _Bubble(msg: _msgs[i]);
          },
        )),

        if (_msgs.length <= 1)
          SizedBox(height: 44, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _send(_suggestions[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
                child: Text(_suggestions[i], style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),
          )),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _textCtrl, maxLines: 4, minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: const InputDecoration(hintText: 'Posez votre question...'),
            )),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _send(_textCtrl.text),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))]),
                child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _confirmClear() => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Effacer l\'historique'),
    content: const Text('Voulez-vous effacer toutes les conversations ?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) await _chatSvc.clearHistory(uid);
          setState(() { _msgs.clear(); _addWelcome(); });
          Navigator.pop(ctx);
        },
        child: const Text('Effacer'),
      ),
    ],
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(margin: const EdgeInsets.only(right: 8, bottom: 4), padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]),
                shape: BoxShape.circle),
              child: const Text('🤖', style: TextStyle(fontSize: 12))),
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser ? LinearGradient(colors: [AppTheme.primary, AppColors.secondary]) : null,
              color: isUser ? null : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.only(
                topLeft   : const Radius.circular(18),
                topRight  : const Radius.circular(18),
                bottomLeft : Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18)),
              boxShadow: [BoxShadow(
                color: (isUser ? AppTheme.primary : Colors.black).withOpacity(0.10),
                blurRadius: 8, offset: const Offset(0, 2))]),
            child: Text(msg.content, style: TextStyle(color: isUser ? Colors.white : null, fontSize: 14, height: 1.5)),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08)),
        ],
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
            Container(margin: EdgeInsets.only(right: i < 2 ? 4 : 0), width: 8, height: 8,
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: Duration(milliseconds: i * 200))
                .then().fadeOut())),
        ),
      ]),
    );
  }
}
