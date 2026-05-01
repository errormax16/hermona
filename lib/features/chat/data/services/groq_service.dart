import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class GroqService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.groq.com/openai/v1',
    headers: {
      'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
      'Content-Type': 'application/json',
    },
  ));

  Future<String> chatCompletion({
    required List<Map<String, dynamic>> messages,
    String model = 'llama-3.3-70b-versatile', // Ou 'mixtral-8x7b-32768'
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
        },
      );
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      throw Exception('Erreur Groq Chat: $e');
    }
  }

  Future<String> transcribeWhisper(String filePath) async {
    try {
      MultipartFile filePart;
      if (kIsWeb) {
        // Sur le web, l'API retourne une URL blob. On récupère les bytes.
        final response = await Dio().get<List<int>>(
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        filePart = MultipartFile.fromBytes(response.data!, filename: 'recording.webm');
      } else {
        filePart = await MultipartFile.fromFile(filePath, filename: 'recording.m4a');
      }

      final formData = FormData.fromMap({
        'file': filePart,
        'model': 'whisper-large-v3',
        'language': 'fr',
        'response_format': 'json',
      });

      final response = await _dio.post(
        '/audio/transcriptions',
        data: formData,
        options: Options(
          // Les headers de BaseOptions sont hérités
        ),
      );
      return response.data['text'];
    } catch (e) {
      throw Exception('Erreur Groq Whisper: $e');
    }
  }
}