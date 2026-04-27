import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).get();
    if (mounted) setState(() { _user = doc.data(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final name  = '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}'.trim();
    final email = _user?['email'] ?? '';
    final init  = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200, pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [AppTheme.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,6))]),
                  child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.headlineMedium).animate().fadeIn(delay: 200.ms),
                Text(email, style: Theme.of(context).textTheme.bodySmall).animate().fadeIn(delay: 300.ms),
              ])),
            ),
          ),
        ),

        SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildListDelegate([
          _stats(),
          const SizedBox(height: 22),
          _section('Historique', [
            _Item(Iconsax.scan,    'Mes analyses',          'Résultats de détection',        () => context.push('/history')),
            _Item(Iconsax.star,    'Mes recommandations',   'Routines et conseils',          () => context.push('/history')),
            _Item(Iconsax.chart_2, 'Mes prédictions',       'Historique des prédictions',    () => context.push('/history')),
            _Item(Iconsax.message, 'Historique chat',       'Conversations assistante',      () => context.push('/history')),
          ]),
          const SizedBox(height: 14),
          _section('Communauté', [
            _Item(Iconsax.people,       'Forum',              'Discussions anonymes', () => context.push('/forum')),
            _Item(Iconsax.message_text, 'Messagerie privée',  'Messages anonymes',    () => context.push('/messages')),
          ]),
          const SizedBox(height: 14),
          _section('Paramètres', [
            _Item(Iconsax.moon,          'Thème',                 'Clair / Sombre',       null, trailing: _ThemeSwitch()),
            _Item(Iconsax.colorfilter,   'Couleur principale',    'Personnaliser',        () => _colorPicker()),
            _Item(Iconsax.document_text, 'Conditions d\'utilisation', '',               () => context.push('/terms')),
          ]),
          const SizedBox(height: 14),

          // Logout
          GestureDetector(
            onTap: () => _logout(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withOpacity(0.2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Iconsax.logout, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Text('Déconnexion', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 80),
        ]))),
      ]),
    );
  }

  Widget _stats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Row(children: [
      _StatCard(label: 'Analyses',    icon: Iconsax.scan,    col: AppConstants.colDetections,      uid: uid),
      const SizedBox(width: 10),
      _StatCard(label: 'Prédictions', icon: Iconsax.chart_2, col: AppConstants.colPredictions,     uid: uid),
      const SizedBox(width: 10),
      _StatCard(label: 'Posts',       icon: Iconsax.people,  col: AppConstants.colForumPosts,      uid: uid),
    ]).animate().fadeIn(delay: 200.ms);
  }

  Widget _section(String title, List<_Item> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 10),
      AppCard(padding: EdgeInsets.zero, child: Column(
        children: items.asMap().entries.map((e) {
          final item   = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, size: 18, color: AppTheme.primary)),
              title: Text(item.title, style: Theme.of(context).textTheme.labelLarge),
              subtitle: item.sub.isNotEmpty ? Text(item.sub, style: Theme.of(context).textTheme.bodySmall) : null,
              trailing: item.trailing ?? Icon(Iconsax.arrow_right_3, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              onTap: item.onTap,
            ),
            if (!isLast) Divider(height: 1, indent: 56, color: Theme.of(context).dividerTheme.color),
          ]);
        }).toList(),
      )).animate().fadeIn(delay: 350.ms),
    ]);
  }

  void _colorPicker() {
    Color current = AppTheme.primary;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Couleur principale'),
      content: SingleChildScrollView(child: ColorPicker(
        pickerColor: current, onColorChanged: (c) => current = c, enableAlpha: false, labelTypes: const [],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(onPressed: () async {
          AppTheme.setPrimary(current);
          final p = await SharedPreferences.getInstance();
          await p.setInt(AppConstants.keyPrimaryColor, current.value);
          if (mounted) setState(() {});
          Navigator.pop(ctx);
        }, child: const Text('Appliquer')),
      ],
    ));
  }

  void _logout() => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Déconnexion'), content: const Text('Voulez-vous vraiment vous déconnecter ?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () async { await FirebaseAuth.instance.signOut(); if (mounted) context.go('/login'); },
        child: const Text('Déconnecter')),
    ],
  ));
}

class _StatCard extends StatelessWidget {
  final String label, col; final IconData icon; final String? uid;
  const _StatCard({required this.label, required this.icon, required this.col, this.uid});
  @override
  Widget build(BuildContext context) => Expanded(child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(col).where('userId', isEqualTo: uid).snapshots(),
    builder: (_, snap) => AppCard(child: Column(children: [
      Icon(icon, color: AppTheme.primary, size: 22),
      const SizedBox(height: 6),
      Text('${snap.data?.docs.length ?? 0}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.primary)),
      Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
    ])),
  ));
}

class _ThemeSwitch extends StatefulWidget {
  @override State<_ThemeSwitch> createState() => _ThemeSwitchState();
}
class _ThemeSwitchState extends State<_ThemeSwitch> {
  bool _dark = false;
  @override
  void initState() { super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => _dark = p.getBool(AppConstants.keyThemeMode) ?? false));
  }
  @override
  Widget build(BuildContext context) => Switch(
    value: _dark, activeColor: AppTheme.primary,
    onChanged: (v) async {
      setState(() => _dark = v);
      AcneIAApp.of(context)?.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
      final p = await SharedPreferences.getInstance();
      await p.setBool(AppConstants.keyThemeMode, v);
    },
  );
}

class _Item { final IconData icon; final String title, sub; final VoidCallback? onTap; final Widget? trailing;
  const _Item(this.icon, this.title, this.sub, this.onTap, {this.trailing}); }
