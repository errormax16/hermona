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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon historique'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabs: const [Tab(text: 'Analyses'), Tab(text: 'Routines'), Tab(text: 'Prédictions'), Tab(text: 'Chats')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _FirestoreList(
          col: AppConstants.colDetections, uid: _uid,
          orderField: 'analyzedAt', emptyTitle: 'Aucune analyse',
          emptySubtitle: 'Analysez votre peau depuis l\'accueil',
          emptyIcon: Iconsax.scan,
          itemBuilder: (ctx, data, id) {
            final score = data['severityScore'] as int? ?? 0;
            final level = data['severityLevel'] as String? ?? 'normal';
            final color = level == 'normal' ? AppColors.severityNormal : level == 'moderate' ? AppColors.severityModerate : AppColors.severitySevere;
            return AppCard(
              onTap: () => ctx.push('/detection/result', extra: data),
              child: Row(children: [
                Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5), width: 2)),
                  child: Center(child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SeverityBadge(label: level == 'normal' ? 'Normal' : level == 'moderate' ? 'Modéré' : 'Sévère', color: color),
                  const SizedBox(height: 4),
                  if (data['analyzedAt'] != null)
                    Text(_ago(data['analyzedAt']), style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11)),
                ])),
                Icon(Iconsax.arrow_right_3, size: 16, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4)),
              ]),
            );
          },
        ),
        _FirestoreList(
          col: AppConstants.colRecommendations, uid: _uid,
          orderField: 'createdAt', emptyTitle: 'Aucune recommandation',
          emptySubtitle: 'Analysez votre peau pour obtenir des recommandations',
          emptyIcon: Iconsax.star,
          itemBuilder: (ctx, data, id) => AppCard(
            onTap: () => ctx.push('/recommendation/${data['detectionId']}', extra: data),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(Iconsax.star, color: AppTheme.primary, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Routine personnalisée', style: Theme.of(ctx).textTheme.labelLarge),
                Text('Durée : ${data['duration'] ?? 'N/A'}', style: Theme.of(ctx).textTheme.bodySmall),
                if (data['createdAt'] != null) Text(_ago(data['createdAt']), style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11)),
              ])),
              Icon(Iconsax.arrow_right_3, size: 16, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4)),
            ]),
          ),
        ),
        _FirestoreList(
          col: AppConstants.colPredictions, uid: _uid,
          orderField: 'predictedAt', emptyTitle: 'Aucune prédiction',
          emptySubtitle: 'Utilisez la prédiction pour anticiper les poussées',
          emptyIcon: Iconsax.chart_2,
          itemBuilder: (ctx, data, id) {
            final risk  = (data['riskScore'] as num?)?.toDouble() ?? 0;
            final level = data['riskLevel'] as String? ?? 'low';
            final color = level == 'low' ? AppColors.severityNormal : level == 'medium' ? AppColors.severityModerate : AppColors.severitySevere;
            return AppCard(child: Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5), width: 2)),
                child: Center(child: Text('${(risk * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)))),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SeverityBadge(label: level == 'low' ? 'Faible' : level == 'medium' ? 'Moyen' : 'Élevé', color: color),
                if (data['predictedAt'] != null) Text(_ago(data['predictedAt']), style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11)),
              ]),
            ]));
          },
        ),
        _FirestoreList(
          col: AppConstants.colChatHistory, uid: _uid, extraWhere: {'role': 'user'},
          orderField: 'timestamp', emptyTitle: 'Aucune conversation',
          emptySubtitle: 'Posez vos questions à l\'assistante IA',
          emptyIcon: Iconsax.message,
          itemBuilder: (ctx, data, id) => AppCard(child: Row(children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Iconsax.message, color: AppTheme.primary, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['content'] ?? '', style: Theme.of(ctx).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (data['timestamp'] != null) Text(_ago(data['timestamp']), style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11)),
            ])),
          ])),
        ),
      ]),
    );
  }

  String _ago(dynamic ts) {
    DateTime dt;
    if (ts is String) dt = DateTime.parse(ts);
    else if (ts is Timestamp) dt = ts.toDate();
    else return '';
    return timeago.format(dt, locale: 'fr');
  }
}

class _FirestoreList extends StatelessWidget {
  final String col;
  final String? uid;
  final String orderField;
  final String emptyTitle, emptySubtitle;
  final IconData emptyIcon;
  final Map<String, dynamic>? extraWhere;
  final Widget Function(BuildContext ctx, Map<String, dynamic> data, String id) itemBuilder;

  const _FirestoreList({
    required this.col, this.uid, required this.orderField,
    required this.emptyTitle, required this.emptySubtitle, required this.emptyIcon,
    required this.itemBuilder, this.extraWhere,
  });

  @override
  Widget build(BuildContext context) {
    Query q = FirebaseFirestore.instance.collection(col).where('userId', isEqualTo: uid);
    if (extraWhere != null) {
      extraWhere!.forEach((k, v) => q = q.where(k, isEqualTo: v));
    }
    // Retiré: .orderBy() pour éviter les erreurs d'Index Composite Firestore !

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur Firestore : \n${snap.error}', 
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonCard())))
          );
        }
        
        final docs = snap.data?.docs.toList() ?? [];
        
        // Tri local en Dart (remplace le orderBy de Firestore)
        docs.sort((a, b) {
           final dataA = a.data() as Map<String, dynamic>;
           final dataB = b.data() as Map<String, dynamic>;
           final tA = dataA[orderField];
           final tB = dataB[orderField];
           
           if (tA == null && tB == null) return 0;
           if (tA == null) return 1;
           if (tB == null) return -1;
           
           DateTime? dtA, dtB;
           if (tA is String) dtA = DateTime.tryParse(tA);
           else if (tA is Timestamp) dtA = tA.toDate();
           
           if (tB is String) dtB = DateTime.tryParse(tB);
           else if (tB is Timestamp) dtB = tB.toDate();

           if (dtA == null || dtB == null) return 0;
           return dtB.compareTo(dtA); // descending
        });

        if (docs.isEmpty) return EmptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
        
        // Limiter à 30 après le tri
        final displayDocs = docs.take(30).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: displayDocs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final data = displayDocs[i].data() as Map<String, dynamic>;
            return FadeInWidget(delay: i * 50, child: itemBuilder(ctx, data, displayDocs[i].id));
          },
        );
      },
    );
  }
}
