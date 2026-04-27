// FILE: features/messaging/presentation/screens/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/messaging_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override State<ConversationsScreen> createState() => _ConversationsScreenState();
}
class _ConversationsScreenState extends State<ConversationsScreen> {
  final _svc = MessagingService();
  @override void initState() { super.initState(); timeago.setLocaleMessages('fr', timeago.FrMessages()); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie privée')),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Iconsax.warning_2, color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Ne partagez jamais vos informations personnelles. Signalez tout contenu suspect.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning))),
          ])).animate().fadeIn(),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _svc.getConversations(),
          builder: (ctx, snap) {
            if (!snap.hasData) return Padding(padding: const EdgeInsets.all(16),
                child: Column(children: List.generate(4, (_) => Padding(padding: const EdgeInsets.only(bottom: 10), child: const SkeletonCard()))));
            final docs = snap.data!.docs;
            if (docs.isEmpty) return EmptyState(icon: Iconsax.message_text, title: 'Aucune conversation', subtitle: 'Démarrez depuis le forum');
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final d    = docs[i].data() as Map<String, dynamic>;
                final date = d['lastMessageAt'] is Timestamp ? (d['lastMessageAt'] as Timestamp).toDate() : DateTime.now();
                return FadeInWidget(delay: i * 60, child: AppCard(
                  onTap: () => ctx.push('/messages/${docs[i].id}'),
                  child: Row(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.6), AppColors.secondary.withOpacity(0.6)]), shape: BoxShape.circle),
                      child: const Icon(Iconsax.user, color: Colors.white, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Utilisatrice anonyme', style: Theme.of(ctx).textTheme.labelLarge),
                        Text(timeago.format(date, locale: 'fr'), style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11)),
                      ]),
                      const SizedBox(height: 4),
                      Text(d['lastMessage'] ?? '', style: Theme.of(ctx).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ])),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, size: 18, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4)),
                      itemBuilder: (_) => [PopupMenuItem(value: 'del', child: Row(children: [Icon(Iconsax.trash, size: 16, color: Colors.red), const SizedBox(width: 8), const Text('Supprimer')]))],
                      onSelected: (v) async { if (v == 'del') await _svc.deleteConversation(docs[i].id); },
                    ),
                  ]),
                ));
              },
            );
          },
        )),
      ]),
    );
  }
}
