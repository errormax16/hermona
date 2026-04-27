import '../entities/prediction_result.dart';

abstract class PredictionRepository {
  /// Envoie les réponses au questionnaire au backend et retourne la prédiction.
  Future<PredictionResult> predict(Map<String, dynamic> answers);

  Future<void> saveResult(PredictionResult result, String userId);
  Future<List<PredictionResult>> getHistory(String userId);
}
