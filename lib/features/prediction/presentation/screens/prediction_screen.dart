import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/prediction_api_service.dart';
import '../../domain/entities/prediction_result.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});
  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  int _step = 0;
  final Map<String, dynamic> _answers = {};
  bool _loading = false;
  PredictionResult? _result;
  final _svc = PredictionApiService();

  static const _questions = [
    _Q('hormonal_cycle', 'Où en êtes-vous dans votre cycle ?', '🌸', [
      _Opt('pre_menstrual', 'Période prémenstruelle (J20-J28)', Iconsax.danger),
      _Opt('menstrual',     'Règles en cours',                 Iconsax.calendar_1),
      _Opt('follicular',    'Phase folliculaire (J1-J13)',     Iconsax.sun_1),
      _Opt('ovulation',     'Ovulation',                       Iconsax.star),
      _Opt('unknown',       'Je ne sais pas',                  Icons.help_outline),
    ]),
    _Q('diet', 'Comment est votre alimentation cette semaine ?', '🥗', [
      _Opt('excellent', 'Excellente – légumes, fruits, eau',      Iconsax.heart),
      _Opt('good',      'Bonne – assez équilibrée',               Iconsax.tick_circle),
      _Opt('average',   'Moyenne – quelques écarts',              Iconsax.minus_cirlce),
      _Opt('bad',       'Mauvaise – fast-food, sucre',            Iconsax.warning_2),
    ]),
    _Q('stress', 'Quel est votre niveau de stress ?', '🧘', [
      _Opt('low',       'Faible – je me sens sereine',            Iconsax.heart),
      _Opt('medium',    'Moyen – quelques préoccupations',        Iconsax.minus_cirlce),
      _Opt('high',      'Élevé – stressée / anxieuse',           Iconsax.warning_2),
      _Opt('very_high', 'Très élevé – épuisée / submergée',      Iconsax.danger),
    ]),
    _Q('sleep', 'Comment dormez-vous ?', '😴', [
      _Opt('excellent', '+8h de sommeil réparateur',              Iconsax.moon),
      _Opt('good',      '7-8h correct',                           Iconsax.tick_circle),
      _Opt('poor',      'Moins de 6h ou sommeil perturbé',        Iconsax.warning_2),
      _Opt('very_poor', 'Insomnie / très mauvaise qualité',       Iconsax.danger),
    ]),
    _Q('temperature', 'Quel temps fait-il ?', '🌡️', [
      _Opt('cold_dry',  'Froid et sec',    Iconsax.wind),
      _Opt('mild',      'Doux / tempéré',  Iconsax.sun_1),
      _Opt('hot_dry',   'Chaud et sec',    Iconsax.sun_fog),
      _Opt('hot_humid', 'Chaud et humide', Iconsax.cloud),
    ]),
    _Q('skincare', 'Avez-vous suivi votre routine ?', '🧴', [
      _Opt('consistent', 'Oui, tous les jours',      Iconsax.tick_circle),
      _Opt('mostly',     'La plupart du temps',      Iconsax.minus_cirlce),
      _Opt('sometimes',  'Parfois seulement',         Iconsax.warning_2),
      _Opt('none',       'Pas du tout cette semaine', Iconsax.close_circle),
    ]),
  ];

  Future<void> _predict() async {
    setState(() => _loading = true);
    try {
      final uid  = FirebaseAuth.instance.currentUser?.uid;
      final res  = await _svc.predict(_answers);
      if (uid != null) {
        try { await _svc.saveResult(res, uid); } catch (_) {}
      }
      if (mounted) setState(() { _result = res; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _ResultView(result: _result!, onRetry: () => setState(() { _result = null; _step = 0; _answers.clear(); }));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prédiction acné'),
        actions: [if (_step > 0) TextButton(
          onPressed: () => setState(() { _step = 0; _answers.clear(); }),
          child: Text('Recommencer', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
        )],
      ),
      body: Column(children: [
        // Progress
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${_step + 1} / ${_questions.length}', style: Theme.of(context).textTheme.bodySmall),
              Text('${((_answers.length / _questions.length) * 100).toInt()}%',
                  style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            LinearPercentIndicator(
              lineHeight: 6,
              percent: _answers.length / _questions.length,
              progressColor: AppTheme.primary,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              barRadius: const Radius.circular(50), padding: EdgeInsets.zero,
              animation: true,
            ),
          ],
        )),

        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: _QuestionView(key: ValueKey(_step), q: _questions[_step], selected: _answers[_questions[_step].key],
            onSelect: (v) {
              setState(() { _answers[_questions[_step].key] = v; });
              if (_step < _questions.length - 1) {
                Future.delayed(const Duration(milliseconds: 300), () => setState(() => _step++));
              }
            }),
        )),

        // Nav
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          if (_step > 0) ...[
            Expanded(child: OutlinedButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back_ios, size: 16), label: const Text('Précédent'),
            )),
            const SizedBox(width: 12),
          ],
          Expanded(flex: 2, child: _step == _questions.length - 1
              ? GradientButton(text: 'Prédire 🔮', onPressed: _predict, isLoading: _loading)
              : _answers.containsKey(_questions[_step].key)
                  ? GradientButton(text: 'Suivant', onPressed: () => setState(() => _step++))
                  : OutlinedButton(onPressed: null, child: const Text('Choisissez une réponse'))),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _QuestionView extends StatelessWidget {
  final _Q q;
  final String? selected;
  final void Function(String) onSelect;
  const _QuestionView({super.key, required this.q, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q.emoji, style: const TextStyle(fontSize: 40)).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 14),
        Text(q.question, style: Theme.of(context).textTheme.headlineLarge)
            .animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 22),
        ...q.options.asMap().entries.map((e) {
          final isSelected = selected == e.value.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onSelect(e.value.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withOpacity(0.10) : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                      width: isSelected ? 2 : 1)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(e.value.icon, color: isSelected ? Colors.white : AppTheme.primary, size: 18)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(e.value.label,
                      style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14))),
                  if (isSelected) Icon(Iconsax.tick_circle5, color: AppTheme.primary, size: 20),
                ]),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 70)).slideX(begin: 0.04),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final PredictionResult result;
  final VoidCallback onRetry;
  const _ResultView({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel == RiskLevel.low    ? AppColors.severityNormal
                : result.riskLevel == RiskLevel.medium ? AppColors.severityModerate
                : AppColors.severitySevere;
    final label = result.riskLevel == RiskLevel.low ? 'Faible' : result.riskLevel == RiskLevel.medium ? 'Moyen' : 'Élevé';
    final trendIcon = result.trend == TrendDirection.increasing ? '📈' : result.trend == TrendDirection.decreasing ? '📉' : '➡️';

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat prédiction')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        FadeInWidget(child: AppCard(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Risque d\'acné', style: Theme.of(context).textTheme.headlineMedium),
            SeverityBadge(label: label, color: color),
          ]),
          const SizedBox(height: 18),
          LinearPercentIndicator(
            lineHeight: 20, percent: result.riskScore,
            progressColor: color, backgroundColor: color.withOpacity(0.15),
            barRadius: const Radius.circular(50),
            center: Text('${(result.riskScore * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            animation: true, animationDuration: 1000),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(trendIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('Tendance : ${result.trend.name == "increasing" ? "En augmentation" : result.trend.name == "decreasing" ? "En diminution" : "Stable"}',
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ]))),
        const SizedBox(height: 14),
        if (result.factors.isNotEmpty)
          FadeInWidget(delay: 200, child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Iconsax.warning_2, color: AppColors.warning, size: 20), const SizedBox(width: 8),
              Text('Facteurs identifiés', style: Theme.of(context).textTheme.headlineMedium)]),
            const SizedBox(height: 14),
            ...result.factors.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6,
                    decoration: BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(f, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ))),
          ]))),
        const SizedBox(height: 14),
        FadeInWidget(delay: 300, child: AppCard(
          color: AppColors.severityNormal.withOpacity(0.06),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Iconsax.shield_tick, color: AppColors.severityNormal, size: 20), const SizedBox(width: 8),
              Text('Conseils de prévention', style: Theme.of(context).textTheme.headlineMedium)]),
            const SizedBox(height: 14),
            ...result.preventionTips.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10),
                child: Text(t, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)))),
          ]),
        )),
        const SizedBox(height: 20),
        FadeInWidget(delay: 400, child: OutlinedButton.icon(
          onPressed: onRetry, icon: const Icon(Iconsax.refresh), label: const Text('Nouvelle prédiction'),
        )),
        const SizedBox(height: 80),
      ])),
    );
  }
}

class _Q { final String key, question, emoji; final List<_Opt> options;
  const _Q(this.key, this.question, this.emoji, this.options); }
class _Opt { final String value, label; final IconData icon;
  const _Opt(this.value, this.label, this.icon); }