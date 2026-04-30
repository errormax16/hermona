import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/forum_service.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _category = 'Tous', _sort = 'date', _search = '';
  final _searchCtrl = TextEditingController();
  final _svc = ForumService();

  @override
  void initState() { super.initState(); timeago.setLocaleMessages('fr', timeago.FrMessages()); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cats = ['Tous', ...AppConstants.forumCategories];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum anonyme'),
        actions: [IconButton(icon: const Icon(Iconsax.shield_tick), onPressed: _safetyNotice)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/forum/create'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau post', style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Rechercher un sujet...',
            prefixIcon: const Icon(Iconsax.search_normal),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.close),
                onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null,
          ),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children: [
          _SortBtn(label: 'Récent',    icon: Iconsax.clock,    active: _sort == 'date',    onTap: () => setState(() => _sort = 'date')),
          const SizedBox(width: 8),
          _SortBtn(label: 'Populaire', icon: Iconsax.trend_up, active: _sort == 'popular', onTap: () => setState(() => _sort = 'popular')),
        ])),
        SizedBox(height: 38, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = cats[i]; final sel = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(50)),
                child: Text(c, style: TextStyle(color: sel ? Colors.white : AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))),
            );
          },
        )),
        const SizedBox(height: 8),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _svc.getPosts(category: _category == 'Tous' ? null : _category, sort: _sort),
          builder: (ctx, snap) {
            if (!snap.hasData) return Padding(padding: const EdgeInsets.all(16),
                child: Column(children: List.generate(4, (_) => Padding(padding: const EdgeInsets.only(bottom: 10), child: const SkeletonCard()))));
            var docs = snap.data!.docs;
            if (_search.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final q = _search.toLowerCase();
                return (data['title'] as String? ?? '').toLowerCase().contains(q) ||
                       (data['content'] as String? ?? '').toLowerCase().contains(q);
              }).toList();
            }
            if (docs.isEmpty) return EmptyState(icon: Iconsax.people, title: 'Pas de post', subtitle: 'Soyez le premier à poster',
                action: TextButton(onPressed: () => context.push('/forum/create'), child: const Text('Créer un post')));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _PostCard(data: data, postId: docs[i].id, svc: _svc, delay: i * 50);
              },
            );
          },
        )),
      ]),
    );
  }

  void _safetyNotice() => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Row(children: [Icon(Iconsax.shield_tick, color: AppTheme.primary), const SizedBox(width: 10), const Text('Espace sécurisé')]),
    content: const Text('🔒 Forum 100% anonyme.\n\n⚠️ Ne partagez JAMAIS :\n• Votre nom réel\n• Votre adresse\n• Votre téléphone\n\n🚨 Signalez tout contenu suspect.', style: TextStyle(height: 1.6)),
    actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris !'))],
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final Map<String, dynamic> data; final String postId; final ForumService svc; final int delay;
  const _PostCard({required this.data, required this.postId, required this.svc, required this.delay});
  @override State<_PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<_PostCard> {
  bool _liked = false;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() { super.initState(); widget.svc.isLiked(widget.postId).then((v) { if (mounted) setState(() => _liked = v); }); }

  @override
  Widget build(BuildContext context) {
    final d      = widget.data;
    final isOwn  = d['authorId'] == _uid;
    final likes  = d['likesCount']  as int? ?? 0;
    final replies= d['repliesCount'] as int? ?? 0;
    final date   = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();

    return FadeInWidget(delay: widget.delay, child: AppCard(
      onTap: () => context.push('/forum/${widget.postId}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
            child: Text(d['category'] ?? 'Général', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600))),
          const Spacer(),
          Text(timeago.format(date, locale: 'fr'), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
          if (isOwn) IconButton(
            icon: Icon(Iconsax.trash, size: 16, color: AppColors.error),
            onPressed: () => _confirmDelete(),
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32), padding: EdgeInsets.zero),
        ]),
        const SizedBox(height: 8),
        Text(d['title'] ?? '', style: Theme.of(context).textTheme.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(d['content'] ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Row(children: [
          GestureDetector(
            onTap: () async {
              await widget.svc.toggleLike(targetId: widget.postId, targetCollection: AppConstants.colForumPosts, counterField: 'likesCount');
              setState(() => _liked = !_liked);
            },
            child: Row(children: [
              Icon(_liked ? Iconsax.heart5 : Iconsax.heart, size: 18, color: _liked ? AppColors.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text('$likes', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 14),
          Row(children: [
            Icon(Iconsax.message, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text('$replies', style: Theme.of(context).textTheme.bodySmall),
          ]),
          const Spacer(),
          GestureDetector(onTap: () => _reportDialog(), child: Icon(Iconsax.flag, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
        ]),
      ]),
    ));
  }

  void _confirmDelete() => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Supprimer ce post ?'), content: const Text('Cette action est irréversible.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () async { await widget.svc.deletePost(widget.postId); Navigator.pop(ctx); },
        child: const Text('Supprimer')),
    ],
  ));

  void _reportDialog() {
    String? reason;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Signaler'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ...['Contenu inapproprié', 'Spam', 'Infos médicales dangereuses', 'Harcèlement'].map((r) =>
          RadioListTile<String>(title: Text(r, style: const TextStyle(fontSize: 13)), value: r, groupValue: reason,
            onChanged: (v) => setSt(() => reason = v), activeColor: AppTheme.primary, contentPadding: EdgeInsets.zero)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: reason == null ? null : () async {
            await widget.svc.reportContent(targetId: widget.postId, targetType: 'post', reason: reason!);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoyé !')));
          }, child: const Text('Signaler')),
      ],
    )));
  }
}

class _SortBtn extends StatelessWidget {
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  const _SortBtn({required this.label, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: active ? AppTheme.primary : AppTheme.primary.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, size: 13, color: active ? AppTheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: active ? AppTheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ]),
    ));
}
