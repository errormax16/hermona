import 'package:equatable/equatable.dart';
import '../../../questionnaire/domain/entities/user_profile.dart';
import '../../../prediction/domain/entities/prediction_result.dart';


// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Chat Entities & Repository
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage extends Equatable {
  final String id;
  final String role;      // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isVoice;
  final String? audioUrl;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isVoice = false,
    this.audioUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id       : j['id']        as String,
    role     : j['role']      as String,
    content  : j['content']   as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
    isVoice  : j['isVoice']   as bool? ?? false,
    audioUrl : j['audioUrl']  as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'role': role,
    'content': content, 'timestamp': timestamp.toIso8601String(),
    'isVoice': isVoice, 'audioUrl': audioUrl,
  };

  @override
  List<Object?> get props => [id];
}

// ─────────────────────────────────────────────────────────────────────────────
abstract class ChatRepository {
  /// Envoie l'historique + le message de l'utilisateur au backend et retourne
  /// la réponse de l'assistante IA.
  Future<String> getResponse({
    required List<ChatMessage> history,
    required String userMessage,
    UserProfile? profile,
    PredictionResult? prediction,
  });


  Future<List<ChatMessage>> loadHistory(String userId);
  Future<void> saveMessage(ChatMessage msg, String userId);
  Future<void> clearHistory(String userId);
  Future<String> transcribeAudio(String path);
}