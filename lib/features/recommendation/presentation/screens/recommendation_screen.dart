import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../detection/data/services/detection_api_service.dart';
import '../../../detection/domain/entities/detection_result.dart';
import '../../data/services/recommendation_api_service.dart';
import '../../domain/entities/recommendation_result.dart';

class RecommendationScreen extends StatefulWidget {
  final String detectionId;
  final Map<String, dynamic>? detectionData;
  const RecommendationScreen({super.key, required this.detectionId, this.detectionData});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  RecommendationResult? _result;
  bool _loading = true;
  final _recSvc  = RecommendationApiService();
  final _detSvc  = DetectionApiService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Check cache
    final cached = await _recSvc.getForDetection(widget.detectionId);
    if (cached != null) { setState(() { _result = cached; _loading = false; }); return; }

    // Build detection from passed data or fetch from Firestore
    DetectionResult detection;
    if (widget.detectionData != null) {
      detection = DetectionResult.fromJson(widget.detectionData!);
    } else {
      final history = await _detSvc.getHistory(uid);
      detection = history.firstWhere((d) => d.id == widget.detectionId,
          orElse: () => history.first);
    }

    final result = await _recSvc.getRecommendations(detection: detection, userId: uid);
    await _recSvc.saveResult(result, uid);
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes recommandations'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(icon: Icon(Iconsax.sun_1),  text: 'Matin'),
            Tab(icon: Icon(Iconsax.moon),   text: 'Soir'),
            Tab(icon: Icon(Iconsax.cup),    text: 'Alimentation'),
          ],
        ),
      ),
      body: _loading
          ? Padding(padding: const EdgeInsets.all(16), child: Column(
              children: List.generate(4, (_) => Padding(padding: const EdgeInsets.only(bottom: 12), child: const SkeletonCard()))))
          : _result == null
              ? const Center(child: Text('Erreur de chargement'))
              : Column(children: [
                  // Duration
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.primary.withOpacity(0.15),
                        AppColors.secondary.withOpacity(0.08),
                      ]),
                      borderRadius: BorderRadius.circular(50)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.clock, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text('Programme de ${_result!.duration}',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ).animate().fadeIn(),

                  Expanded(child: TabBarView(controller: _tab, children: [
                    _RoutineTab(steps: _result!.morningRoutine, isMorning: true),
                    _RoutineTab(steps: _result!.eveningRoutine, isMorning: false),
                    _DietTab(tips: _result!.dietTips),
                  ])),
                ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RoutineTab extends StatelessWidget {
  final List<RoutineStep> steps;
  final bool isMorning;
  const _RoutineTab({required this.steps, required this.isMorning});

  @override
  Widget build(BuildContext context) {
    final color = isMorning ? AppColors.warning : AppColors.info;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.04)]),
          borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Text(isMorning ? '☀️' : '🌙', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMorning ? 'Routine du matin' : 'Routine du soir',
                style: Theme.of(context).textTheme.headlineMedium),
            Text(isMorning ? 'Bien commencer la journée' : 'Régénérer votre peau',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      ).animate().fadeIn(),
      const SizedBox(height: 18),
      ...steps.asMap().entries.map((e) => FadeInWidget(
        delay: e.key * 80,
        child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppColors.secondary]),
                shape: BoxShape.circle),
              child: Center(child: Text(e.value.icon, style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 14),
            Expanded(child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value.product, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(e.value.instruction, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
            ]))),
          ],
        )),
      )),
    ]);
  }
}

class _DietTab extends StatelessWidget {
  final List<String> tips;
  const _DietTab({required this.tips});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.accent.withOpacity(0.3), AppColors.accent.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Text('🥗', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Conseils alimentaires', style: Theme.of(context).textTheme.headlineMedium),
            Text('Rayonner de l\'intérieur', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      ).animate().fadeIn(),
      const SizedBox(height: 16),
      ...tips.asMap().entries.map((e) => FadeInWidget(
        delay: e.key * 70,
        child: Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(
          child: Text(e.value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55)),
        )),
      )),
      const SizedBox(height: 80),
    ]);
  }
}
