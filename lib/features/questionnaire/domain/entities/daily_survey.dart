import 'package:cloud_firestore/cloud_firestore.dart';

class DailySurvey {
  final String id;
  final String userId;
  final DateTime date;
  final int stress;
  final double sleepDuration;
  final int sleepQuality;
  final int hydration;
  final List<String> food;
  final List<String> symptoms;
  final int cycleDay;
  final String cyclePhase;
  final int lifestyleScore;

  DailySurvey({
    required this.id,
    required this.userId,
    required this.date,
    required this.stress,
    required this.sleepDuration,
    required this.sleepQuality,
    required this.hydration,
    required this.food,
    required this.symptoms,
    required this.cycleDay,
    required this.cyclePhase,
    required this.lifestyleScore,
  });

  factory DailySurvey.fromJson(Map<String, dynamic> json, String id) {
    return DailySurvey(
      id: id,
      userId: json['userId'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      stress: json['stress'] ?? 0,
      sleepDuration: (json['sleepDuration'] ?? 0).toDouble(),
      sleepQuality: json['sleepQuality'] ?? 0,
      hydration: json['hydration'] ?? 0,
      food: List<String>.from(json['food'] ?? []),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      cycleDay: json['cycleDay'] ?? 0,
      cyclePhase: json['cyclePhase'] ?? '',
      lifestyleScore: json['lifestyleScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'stress': stress,
      'sleepDuration': sleepDuration,
      'sleepQuality': sleepQuality,
      'hydration': hydration,
      'food': food,
      'symptoms': symptoms,
      'cycleDay': cycleDay,
      'cyclePhase': cyclePhase,
      'lifestyleScore': lifestyleScore,
    };
  }
}
