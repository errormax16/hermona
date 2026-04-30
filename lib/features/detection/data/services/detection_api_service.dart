import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/detection_result.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';

class DetectionApiService implements DetectionRepository {

  // Configuration de Dio
  final Dio _dio;
  
  DetectionApiService()
      : _dio = Dio(BaseOptions(
          baseUrl        : 'http://10.202.31.129:8000', // Adresse IP Wi-Fi de l'ordinateur
          connectTimeout : const Duration(seconds: 30),
          receiveTimeout : const Duration(seconds: 60),
        ));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<DetectionResult> analyzeImages(List<File> images) async {
    try {
      final formData = FormData();
      for (int i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'files', // Doit correspondre à `files: List[UploadFile]` dans FastAPI
          await MultipartFile.fromFile(
            images[i].path,
            filename: 'image_$i.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        ));
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/predict',
        data: formData,
      );

      return DetectionResult.fromJson(response.data!);

    } on DioException catch (e) {
      final errorDetail = e.response?.data;
      final msg = e.response != null 
          ? 'Erreur Serveur (${e.response?.statusCode}): $errorDetail'
          : 'Erreur Réseau: ${e.message}';
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException('Erreur inattendue: $e');
    }
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
