import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dio/dio.dart';

import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../../../core/constants/app_constants.dart';
// import '../../../../core/errors/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – Implémentation du PredictionRepository
//
// ✅ MOCK ACTIF  – calcul local basé sur les réponses
// 🔌 API RÉELLE  – commentée, endpoint : POST /predict
//
// Pour passer à l'API réelle :
//   1. Décommentez les imports Dio et ApiException
//   2. Décommentez le bloc [API RÉELLE] dans predict()
//   3. Supprimez le bloc [MOCK – À SUPPRIMER]
// ─────────────────────────────────────────────────────────────────────────────
class PredictionApiService implements PredictionRepository {

  // final Dio _dio;
  // PredictionApiService()
  //     : _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<PredictionResult> predict(Map<String, dynamic> answers) async {

    // ════════════════════════════════════════════════════════════════════════
    // [API RÉELLE] – POST /predict
    // ════════════════════════════════════════════════════════════════════════
    // try {
    //   final response = await _dio.post<Map<String, dynamic>>(
    //     '/predict',
    //     data: {'answers': answers},
    //   );
    //   return PredictionResult.fromJson(response.data!);
    // } on DioException catch (e) {
    //   throw ApiException(
    //     e.response?.data?['detail'] ?? 'Erreur de prédiction',
    //     statusCode: e.response?.statusCode,
    //   );
    // }
    // ════════════════════════════════════════════════════════════════════════

    // ════════════════════════════════════════════════════════════════════════
    // [MOCK – À SUPPRIMER] – Calcul de risque local
    // ════════════════════════════════════════════════════════════════════════
    await Future.delayed(const Duration(seconds: 2));

    double risk = 0.25;
    final factors      = <String>[];
    final tips         = <String>[];

    if (answers['hormonal_cycle'] == 'pre_menstrual') {
      risk += 0.20;
      factors.add('Période prémenstruelle (pic d\'androgènes)');
    }
    if (answers['diet'] == 'bad') {
      risk += 0.15;
      factors.add('Alimentation pro-inflammatoire');
    }
    if (answers['stress'] == 'high' || answers['stress'] == 'very_high') {
      risk += 0.15;
      factors.add('Niveau de stress élevé (cortisol)');
    }
    if (answers['sleep'] == 'poor' || answers['sleep'] == 'very_poor') {
      risk += 0.10;
      factors.add('Manque ou mauvaise qualité de sommeil');
    }
    if (answers['temperature'] == 'hot_humid') {
      risk += 0.10;
      factors.add('Chaleur et humidité (sudation excessive)');
    }
    if (answers['skincare'] == 'none' || answers['skincare'] == 'sometimes') {
      risk += 0.08;
      factors.add('Routine de soins irrégulière');
    }

    risk = risk.clamp(0.0, 1.0);

    final level = risk < 0.35
        ? RiskLevel.low
        : risk < 0.65
            ? RiskLevel.medium
            : RiskLevel.high;

    final trend = risk > 0.60
        ? TrendDirection.increasing
        : risk < 0.35
            ? TrendDirection.decreasing
            : TrendDirection.stable;

    tips.addAll([
      '🧘 10 min de méditation / jour pour réguler le cortisol',
      '💤 7-9h de sommeil pour la régénération cellulaire',
      '🌊 Nettoyez le visage après chaque transpiration',
      '💊 Zinc et vitamine A : suppléments anti-acné reconnus',
      '📅 Respectez votre routine matin ET soir',
    ]);

    return PredictionResult(
      id            : 'pred_${DateTime.now().millisecondsSinceEpoch}',
      riskScore     : double.parse(risk.toStringAsFixed(2)),
      riskLevel     : level,
      trend         : trend,
      factors       : factors.isEmpty ? ['Aucun facteur de risque majeur identifié'] : factors,
      preventionTips: tips,
      predictedAt   : DateTime.now(),
    );
    // ════════════════════════════════════════════════════════════════════════
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> saveResult(PredictionResult result, String userId) async {
    await _db
        .collection(AppConstants.colPredictions)
        .doc(result.id)
        .set({...result.toJson(), 'userId': userId});
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<List<PredictionResult>> getHistory(String userId) async {
    final snap = await _db
        .collection(AppConstants.colPredictions)
        .where('userId', isEqualTo: userId)
        .orderBy('predictedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => PredictionResult.fromJson(d.data()))
        .toList();
  }
}
