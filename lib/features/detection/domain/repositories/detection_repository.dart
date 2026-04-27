import 'dart:io';
import '../entities/detection_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Interface du repository de détection
// Implémenté dans data/services/detection_api_service.dart
// ─────────────────────────────────────────────────────────────────────────────
abstract class DetectionRepository {
  /// Envoie les images au backend Python et retourne le résultat de détection.
  Future<DetectionResult> analyzeImages(List<File> images);

  /// Récupère l'historique des détections de l'utilisateur depuis Firestore.
  Future<List<DetectionResult>> getHistory(String userId);

  /// Sauvegarde un résultat dans Firestore.
  Future<void> saveResult(DetectionResult result, String userId);
}
