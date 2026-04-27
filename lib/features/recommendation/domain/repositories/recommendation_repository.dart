import '../entities/recommendation_result.dart';
import '../../../detection/domain/entities/detection_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Interface du repository de recommandation
// ─────────────────────────────────────────────────────────────────────────────
abstract class RecommendationRepository {
  /// Génère une routine personnalisée à partir du résultat de détection.
  Future<RecommendationResult> getRecommendations({
    required DetectionResult detection,
    required String userId,
  });

  Future<void> saveResult(RecommendationResult result, String userId);
  Future<RecommendationResult?> getForDetection(String detectionId);
}
