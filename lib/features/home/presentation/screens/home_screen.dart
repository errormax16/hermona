import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../detection/data/services/detection_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker     = ImagePicker();
  final _detection  = DetectionApiService();
  final List<File> _images = [];
  bool _analyzing = false;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkWelcome();
  }

  void _loadUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colUsers).doc(uid).get()
        .then((d) { if (d.exists && mounted) setState(() => _firstName = d.data()?['firstName'] as String?); });
  }

  Future<void> _checkWelcome() async {
    final p = await SharedPreferences.getInstance();
    if (!(p.getBool(AppConstants.keyWelcomeShown) ?? false) && mounted) {
      await p.setBool(AppConstants.keyWelcomeShown, true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcome());
    }
  }

  void _showWelcome() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.1)]),
            shape: BoxShape.circle),
          child: const Text('🌸', style: TextStyle(fontSize: 48)),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 18),
        Text('Bienvenue, ${_firstName ?? 'beauté'} ! 💕',
          style: Theme.of(ctx).textTheme.displaySmall, textAlign: TextAlign.center)
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 10),
        Text('AcnéIA vous accompagne dans votre parcours beauté. Analysez votre peau et recevez des recommandations personnalisées !',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6), textAlign: TextAlign.center)
            .animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 20),
        _feat(ctx, Iconsax.scan,    'Analyse IA de votre peau'),
        const SizedBox(height: 8),
        _feat(ctx, Iconsax.star,    'Routines personnalisées'),
        const SizedBox(height: 8),
        _feat(ctx, Iconsax.chart_2, 'Prédictions & suivi'),
        const SizedBox(height: 8),
        _feat(ctx, Iconsax.people,  'Communauté anonyme'),
        const SizedBox(height: 24),
        GradientButton(text: 'C\'est parti ! 🚀', onPressed: () => Navigator.pop(ctx))
            .animate().fadeIn(delay: 500.ms),
      ])),
    ));
  }

  Widget _feat(BuildContext ctx, IconData icon, String text) => Row(children: [
    Container(padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: AppTheme.primary)),
    const SizedBox(width: 10),
    Text(text, style: Theme.of(ctx).textTheme.bodyMedium),
  ]);

  Future<void> _pick(ImageSource src) async {
    try {
      if (src == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 85);
        if (files.isNotEmpty) setState(() => _images.addAll(files.map((f) => File(f.path))));
      } else {
        final f = await _picker.pickImage(source: src, imageQuality: 85);
        if (f != null) setState(() => _images.add(File(f.path)));
      }
    } catch (_) {}
  }

  Future<void> _analyze() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins une photo')));
      return;
    }
    setState(() => _analyzing = true);
    try {
      final uid  = FirebaseAuth.instance.currentUser!.uid;
      final result = await _detection.analyzeImages(_images);
      await _detection.saveResult(result, uid);
      if (mounted) context.push('/detection/result', extra: result.toJson());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        // AppBar
        SliverAppBar(
          expandedHeight: 110, floating: true, snap: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('Bonjour ${_firstName ?? ''} 🌸', style: Theme.of(context).textTheme.headlineLarge),
                  Text('Comment va votre peau ?', style: Theme.of(context).textTheme.bodySmall),
                ]),
                Row(children: [
                  IconButton(icon: const Icon(Iconsax.message_text), onPressed: () => context.push('/messages')),
                  IconButton(icon: const Icon(Iconsax.people),       onPressed: () => context.push('/forum')),
                ]),
              ],
            ),
          ),
        ),

        SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildListDelegate([
          _buildLastAnalysis(),
          const SizedBox(height: 22),

          Text('Analyser ma peau', style: Theme.of(context).textTheme.headlineLarge)
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 4),
          Text('Ajoutez des photos pour une analyse IA', style: Theme.of(context).textTheme.bodySmall)
              .animate().fadeIn(delay: 280.ms),
          const SizedBox(height: 14),

          // Photo tips
          _buildPhotoTips(),
          const SizedBox(height: 14),

          // Upload zone
          _buildUploadZone(),
          const SizedBox(height: 14),

          // Previews
          if (_images.isNotEmpty) ...[_buildPreviews(), const SizedBox(height: 14)],

          if (_images.isNotEmpty)
            GradientButton(
              text: _analyzing ? 'Analyse en cours...' : 'Analyser ma peau 🔬',
              icon: _analyzing ? null : Iconsax.scan,
              onPressed: _analyzing ? null : _analyze,
              isLoading: _analyzing,
            ).animate().fadeIn().slideY(begin: 0.15),

          const SizedBox(height: 22),
          _buildShortcuts(),
          const SizedBox(height: 80),
        ]))),
      ]),
    );
  }

  Widget _buildLastAnalysis() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.colDetections)
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true).limit(1).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return AppCard(child: Row(children: [
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Iconsax.camera, color: AppTheme.primary)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Première analyse', style: Theme.of(ctx).textTheme.labelLarge),
              Text('Commencez votre parcours beauté !', style: Theme.of(ctx).textTheme.bodySmall),
            ])),
          ])).animate().fadeIn(delay: 100.ms);
        }
        final data  = snap.data!.docs.first.data() as Map<String, dynamic>;
        final score = data['severityScore'] as int;
        final level = data['severityLevel'] as String;
        final color = level == 'normal' ? AppColors.severityNormal
                    : level == 'moderate' ? AppColors.severityModerate
                    : AppColors.severitySevere;
        final label = level == 'normal' ? 'Normal' : level == 'moderate' ? 'Modéré' : 'Sévère';
        return AppCard(
          onTap: () => context.push('/detection/result', extra: data),
          child: Row(children: [
            Container(width: 54, height: 54,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 2)),
              child: Center(child: Text('$score', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dernière analyse', style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 4),
              SeverityBadge(label: label, color: color),
            ])),
            Icon(Iconsax.arrow_right_3, size: 16, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4)),
          ]),
        ).animate().fadeIn(delay: 100.ms);
      },
    );
  }

  Widget _buildPhotoTips() {
    return AppCard(
      color: AppTheme.primary.withOpacity(0.04),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(children: [
          Icon(Iconsax.info_circle, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text('Conseils photo', style: Theme.of(context).textTheme.labelLarge),
        ]),
        children: [Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonnes pratiques', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppConstants.photoTipsGood, style: Theme.of(context).textTheme.bodySmall),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('À éviter', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppConstants.photoTipsBad, style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
        )],
      ),
    );
  }

  Widget _buildUploadZone() {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => _pick(ImageSource.camera),
        child: Container(height: 96,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.primary.withOpacity(0.04)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Iconsax.camera, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text('Prendre une photo', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ).animate().fadeIn(delay: 360.ms).slideX(begin: -0.08)),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: () => _pick(ImageSource.gallery),
        child: Container(height: 96,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.secondary.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.secondary.withOpacity(0.04)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Iconsax.gallery, color: AppColors.secondary, size: 28),
            const SizedBox(height: 8),
            Text('Importer galerie', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ).animate().fadeIn(delay: 440.ms).slideX(begin: 0.08)),
    ]);
  }

  Widget _buildPreviews() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${_images.length} photo(s)', style: Theme.of(context).textTheme.bodySmall),
        TextButton(
          onPressed: () => setState(() => _images.clear()),
          child: Text('Effacer tout', style: TextStyle(color: AppColors.error, fontSize: 12))),
      ]),
      SizedBox(height: 88, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14),
            child: Image.file(_images[i], width: 88, height: 88, fit: BoxFit.cover)),
          Positioned(top: 4, right: 4, child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(i)),
            child: Container(padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 12)),
          )),
        ]),
      )),
    ]).animate().fadeIn().slideY(begin: 0.08);
  }

  Widget _buildShortcuts() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(title: 'Accès rapide', action: 'Historique', onAction: () => context.push('/history')),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.6,
        children: [
          _sc(Iconsax.message,  'Assistant IA',  AppTheme.primary,    () => context.go('/chat')),
          _sc(Iconsax.chart_2,  'Prédictions',   AppColors.secondary, () => context.go('/prediction')),
          _sc(Iconsax.people,   'Forum',          AppColors.accent,    () => context.push('/forum')),
          _sc(Iconsax.clock,    'Historique',     AppColors.info,      () => context.push('/history')),
        ],
      ),
    ]).animate().fadeIn(delay: 400.ms);
  }

  Widget _sc(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 24),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
}
