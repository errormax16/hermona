import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Chat Entities & Repository
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage extends Equatable {
  final String id;
  final String role;      // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id       : j['id']        as String,
    role     : j['role']      as String,
    content  : j['content']   as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'role': role,
    'content': content, 'timestamp': timestamp.toIso8601String(),
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
  });

  Future<List<ChatMessage>> loadHistory(String userId);
  Future<void> saveMessage(ChatMessage msg, String userId);
  Future<void> clearHistory(String userId);
}
