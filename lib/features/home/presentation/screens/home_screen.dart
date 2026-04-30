import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

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
  }

  void _loadUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colUsers).doc(uid).get()
        .then((d) { if (d.exists && mounted) setState(() => _firstName = d.data()?['firstName'] as String?); });
  }

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour ${_firstName ?? ''} 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prête à prendre soin de ta peau ?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: const Text('🌸', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Iconsax.logout),
                  color: AppColors.error,
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/welcome');
                  },
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.2),
            
            const SizedBox(height: 32),
            
            // Questionnaires Dashboard
            SectionTitle(title: 'Suivi & Bilans', action: '', onAction: () {}),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildSurveyCard(
                    context, 
                    title: 'Mon Profil', 
                    subtitle: 'Onboarding', 
                    icon: Iconsax.user, 
                    color: AppTheme.primary, 
                    onTap: () => context.push('/onboarding')
                  ),
                  const SizedBox(width: 16),
                  _buildSurveyCard(
                    context, 
                    title: 'Bilan', 
                    subtitle: 'Quotidien', 
                    icon: Iconsax.calendar_1, 
                    color: AppColors.secondary, 
                    onTap: () => context.push('/daily-survey')
                  ),
                  const SizedBox(width: 16),
                  _buildSurveyCard(
                    context, 
                    title: 'Bilan', 
                    subtitle: 'Hebdomadaire', 
                    icon: Iconsax.health, 
                    color: AppColors.accent, 
                    onTap: () => context.push('/weekly-survey')
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),

            const SizedBox(height: 32),

            // AI Analysis Section
            SectionTitle(title: 'Analyse de peau IA', action: '', onAction: () {}),
            const SizedBox(height: 16),
            _buildLastAnalysis(),
            const SizedBox(height: 16),
            _buildUploadZone(),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPreviews(),
              const SizedBox(height: 16),
              GradientButton(
                text: _analyzing ? 'Analyse en cours...' : 'Analyser les photos',
                onPressed: _analyzing ? null : _analyze,
              ).animate().fadeIn().slideY(begin: 0.1),
            ],

            const SizedBox(height: 32),
            _buildShortcuts(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ),
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
            Text('Prendre photo', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
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
