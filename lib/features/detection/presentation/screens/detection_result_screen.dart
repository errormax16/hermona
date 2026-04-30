import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/detection_result.dart';

class DetectionResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetectionResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final result = DetectionResult.fromJson(data);
    final color  = result.severityLevel == SeverityLevel.normal   ? AppColors.severityNormal
                 : result.severityLevel == SeverityLevel.moderate ? AppColors.severityModerate
                 : AppColors.severitySevere;
    final label  = result.severityLevel == SeverityLevel.normal   ? 'Normal'
                 : result.severityLevel == SeverityLevel.moderate ? 'Modéré' : 'Sévère';
    final msg    = result.severityLevel == SeverityLevel.normal
        ? 'Votre peau est en bonne santé ! Maintenez votre routine.'
        : result.severityLevel == SeverityLevel.moderate
        ? 'Acné modérée détectée. Un traitement adapté est recommandé.'
        : 'Acné sévère. Consultez un dermatologue en complément des soins.';

    final pieColors = [AppTheme.primary, AppColors.secondary, AppColors.accent, AppColors.warning, AppColors.info];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de l\'analyse'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.go('/home')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Annotated Images ────────────────────────────────────────────
          if (result.imageUrls.isNotEmpty)
            ...result.imageUrls.map((url) {
              if (url.startsWith('data:image')) {
                final base64str = url.split(',').last;
                return FadeInWidget(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        base64Decode(base64str),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

          // ── Score card ──────────────────────────────────────────────────
          FadeInWidget(child: AppCard(child: Column(children: [
            Text('Score de sévérité', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 80, lineWidth: 12,
              percent: result.severityScore / 100,
              progressColor: color,
              backgroundColor: color.withOpacity(0.15),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true, animationDuration: 1200,
              center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${result.severityScore}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                Text('/100', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            const SizedBox(height: 16),
            SeverityBadge(label: label, color: color),
            const SizedBox(height: 10),
            Text(msg, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ]))),

          const SizedBox(height: 14),

          // ── Pie chart ───────────────────────────────────────────────────
          FadeInWidget(delay: 200, child: AppCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Types d\'acné détectés', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              SizedBox(height: 200, child: PieChart(PieChartData(
                sections: result.classifications.asMap().entries.map((e) =>
                  PieChartSectionData(
                    color: pieColors[e.key % pieColors.length],
                    value: e.value.percentage * 100,
                    title: '${(e.value.percentage * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  )).toList(),
                centerSpaceRadius: 40, sectionsSpace: 4,
              ))),
              const SizedBox(height: 10),
              ...result.classifications.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(width: 12, height: 12,
                      decoration: BoxDecoration(color: pieColors[e.key % pieColors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(e.value.type, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${(e.value.percentage * 100).round()}%',
                      style: TextStyle(color: pieColors[e.key % pieColors.length], fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              )),
            ],
          ))),

          const SizedBox(height: 14),

          // ── Detail cards per acne type ──────────────────────────────────
          ...result.classifications.asMap().entries.map((e) => FadeInWidget(
            delay: 300 + e.key * 100,
            child: Padding(padding: const EdgeInsets.only(bottom: 12), child: AppCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
                    child: Text(e.value.type, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const Spacer(),
                  Text('${(e.value.percentage * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary)),
                ]),
                const SizedBox(height: 10),
                Text(e.value.description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.25))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💡 ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(e.value.cause,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5))),
                  ]),
                ),
              ],
            ))),
          )),

          const SizedBox(height: 14),

          // ── CTA ─────────────────────────────────────────────────────────
          FadeInWidget(delay: 600, child: GradientButton(
            text: 'Voir mes recommandations 🌟',
            icon: Iconsax.star,
            onPressed: () => context.push(
              '/recommendation/${data['id']}',
              extra: data,
            ),
          )),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
