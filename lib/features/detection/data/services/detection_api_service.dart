import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dio/dio.dart';

import '../../domain/entities/detection_result.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../../../core/constants/app_constants.dart';
// import '../../../../core/errors/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – Implémentation du DetectionRepository
//
// ✅ MOCK ACTIF  – simulation locale, fonctionne sans backend
// 🔌 API RÉELLE  – commentée, prête à décommenter
//
// Pour passer à l'API réelle :
//   1. Décommentez les imports Dio et ApiException
//   2. Décommentez les blocs marqués [API RÉELLE]
//   3. Supprimez ou commentez les blocs marqués [MOCK – À SUPPRIMER]
// ─────────────────────────────────────────────────────────────────────────────
class DetectionApiService implements DetectionRepository {

  // ── Dio (décommenter quand API prête) ────────────────────────────────────
  // final Dio _dio;
  // DetectionApiService()
  //     : _dio = Dio(BaseOptions(
  //         baseUrl        : AppConstants.apiBaseUrl,
  //         connectTimeout : const Duration(seconds: 30),
  //         receiveTimeout : const Duration(seconds: 60),
  //       ));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Données statiques du mock (À SUPPRIMER quand API réelle active) ──────
  static const Map<String, Map<String, String>> _acneData = {
    'Blackhead': {
      'cause':
          'Pores obstrués par excès de sébum oxydé au contact de l\'air',
      'description':
          'Points noirs visibles, principalement sur le nez et le front',
    },
    'Whitehead': {
      'cause':
          'Pores totalement fermés piégeant sébum et cellules mortes',
      'description':
          'Petits boutons blancs sous la peau, sans contact avec l\'air',
    },
    'Papule': {
      'cause': 'Inflammation due aux bactéries P. acnes dans les pores',
      'description': 'Bosses rouges et douloureuses sans pus visible',
    },
    'Pustule': {
      'cause':
          'Infection bactérienne avec accumulation de pus dans le follicule',
      'description':
          'Boutons avec centre blanc/jaune entouré de peau rouge',
    },
    'Nodule': {
      'cause':
          'Infection profonde touchant les couches inférieures de la peau',
      'description':
          'Grosses bosses dures et douloureuses sous la peau',
    },
  };

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<DetectionResult> analyzeImages(List<File> images) async {

    // ════════════════════════════════════════════════════════════════════════
    // [API RÉELLE] – Décommenter ce bloc et supprimer le bloc MOCK ci-dessous
    // ════════════════════════════════════════════════════════════════════════
    // try {
    //   final formData = FormData();
    //   for (int i = 0; i < images.length; i++) {
    //     formData.files.add(MapEntry(
    //       'images',
    //       await MultipartFile.fromFile(
    //         images[i].path,
    //         filename: 'image_$i.jpg',
    //         contentType: DioMediaType('image', 'jpeg'),
    //       ),
    //     ));
    //   }
    //
    //   final response = await _dio.post<Map<String, dynamic>>(
    //     '/detect',
    //     data: formData,
    //   );
    //
    //   return DetectionResult.fromJson(response.data!);
    //
    // } on DioException catch (e) {
    //   throw ApiException(
    //     e.response?.data?['detail'] ?? 'Erreur de détection',
    //     statusCode: e.response?.statusCode,
    //   );
    // }
    // ════════════════════════════════════════════════════════════════════════

    // ════════════════════════════════════════════════════════════════════════
    // [MOCK – À SUPPRIMER] – Simulation locale
    // ════════════════════════════════════════════════════════════════════════
    await Future.delayed(const Duration(seconds: 3)); // simulation latence API

    // Score aléatoire reproductible basé sur le nombre d'images
    final score = 20 + (images.length * 13 + 37) % 65;
    final level = score < 30
        ? SeverityLevel.normal
        : score < 65
            ? SeverityLevel.moderate
            : SeverityLevel.severe;

    final types  = ['Blackhead', 'Papule', 'Pustule'];
    double remaining = 1.0;
    final classes = <AcneClassification>[];

    for (int i = 0; i < types.length; i++) {
      final pct = i == types.length - 1
          ? remaining
          : double.parse((0.15 + i * 0.15).toStringAsFixed(2));
      remaining -= pct;
      classes.add(AcneClassification(
        type       : types[i],
        percentage : pct.clamp(0.0, 1.0),
        cause      : _acneData[types[i]]!['cause']!,
        description: _acneData[types[i]]!['description']!,
      ));
    }

    return DetectionResult(
      id             : 'mock_${DateTime.now().millisecondsSinceEpoch}',
      severityScore  : score,
      severityLevel  : level,
      classifications: classes,
      analyzedAt     : DateTime.now(),
      imageUrls      : [],
    );
    // ════════════════════════════════════════════════════════════════════════
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<List<DetectionResult>> getHistory(String userId) async {
    final snap = await _db
        .collection(AppConstants.colDetections)
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .get();

    return snap.docs
        .map((d) => DetectionResult.fromJson(d.data()))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> saveResult(DetectionResult result, String userId) async {
    await _db
        .collection(AppConstants.colDetections)
        .doc(result.id)
        .set({...result.toJson(), 'userId': userId});
  }
}
