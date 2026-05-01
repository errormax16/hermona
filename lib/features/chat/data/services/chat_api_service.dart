import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../questionnaire/domain/entities/user_profile.dart';
import '../../../prediction/domain/entities/prediction_result.dart';
// import removed

class ChatApiService implements ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  @override
  Future<String> getResponse({
    required List<ChatMessage> history,
    required String userMessage,
    UserProfile? profile,
    PredictionResult? prediction,
  }) async {
    try {
      // Préparer le payload attendu par le backend FastAPI
      final payload = {
        "message": userMessage,
        "profile": {
          "age": profile?.age ?? 25,
          "pcos": profile?.sopk == true ? 1 : 0,
          "type_peau": profile?.skinType ?? "mixte",
          "imc": 22.0, // Valeurs par défaut si non dispos
        },
        "daily": {
          "stress": 5.0,
          "sommeil": 7.0,
          "hydratation_verres": 6,
        },
        "hormonal": {
          "jour_cycle": 14,
          "phase": "folliculaire",
        },
        "history": history
            .takeLast(6)
            .map((m) => {
                  "role": m.role,
                  "content": m.content,
                })
            .toList(),
      };

      // Forcer l'URL de base pour éviter tout cache persistant de localhost
      _dio.options.baseUrl = 'http://10.202.31.129:8000';
      
      final response = await _dio.post('/chat', data: payload);
      return response.data['response'] ?? "Désolée, je n'ai pas pu répondre.";
    } catch (e) {
      throw Exception('Erreur de connexion au serveur : $e');
    }
  }

  @override
  Future<List<ChatMessage>> loadHistory(String userId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colChatHistory)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp')
          .limit(60)
          .get();
      return snap.docs.map((d) => ChatMessage.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('Chat history load failed: $e');
      return [];
    }
  }

  @override
  Future<void> saveMessage(ChatMessage msg, String userId) async {
    try {
      await _db
          .collection(AppConstants.colChatHistory)
          .doc(msg.id)
          .set({...msg.toJson(), 'userId': userId});
    } catch (e) {
      debugPrint('Chat message save failed: $e');
    }
  }

  @override
  Future<void> clearHistory(String userId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colChatHistory)
          .where('userId', isEqualTo: userId)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Chat clear history failed: $e');
    }
  }

  @override
  Future<String> transcribeAudio(String path) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'audio.m4a'),
      });
      
      // Forcer l'URL de base pour éviter tout cache persistant
      _dio.options.baseUrl = 'http://10.202.31.129:8000';
      
      final response = await _dio.post('/transcribe', data: formData);
      return response.data['text'] ?? '';
    } catch (e) {
      throw Exception('Erreur de transcription : $e');
    }
  }
}

extension ListExtensions<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}