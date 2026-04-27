import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklySurvey {
  final String id;
  final String userId;
  final int weekNumber;
  final int year;
  final Map<String, String> photos;
  final String makeupFrequency;
  final String makeupType;
  final String makeupRemoval;
  final String cleansingFrequency;
  final String routineFollowed;
  final String spfThisWeek;
  final bool autoCorrection;
  final bool reminderSent;
  final bool spfAlert;

  WeeklySurvey({
    required this.id,
    required this.userId,
    required this.weekNumber,
    required this.year,
    required this.photos,
    required this.makeupFrequency,
    required this.makeupType,
    required this.makeupRemoval,
    required this.cleansingFrequency,
    required this.routineFollowed,
    required this.spfThisWeek,
    required this.autoCorrection,
    required this.reminderSent,
    required this.spfAlert,
  });

  factory WeeklySurvey.fromJson(Map<String, dynamic> json, String id) {
    return WeeklySurvey(
      id: id,
      userId: json['userId'] ?? '',
      weekNumber: json['weekNumber'] ?? 0,
      year: json['year'] ?? 0,
      photos: Map<String, String>.from(json['photos'] ?? {}),
      makeupFrequency: json['makeupFrequency'] ?? '',
      makeupType: json['makeupType'] ?? '',
      makeupRemoval: json['makeupRemoval'] ?? '',
      cleansingFrequency: json['cleansingFrequency'] ?? '',
      routineFollowed: json['routineFollowed'] ?? '',
      spfThisWeek: json['spfThisWeek'] ?? '',
      autoCorrection: json['autoCorrection'] ?? false,
      reminderSent: json['reminderSent'] ?? false,
      spfAlert: json['spfAlert'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'weekNumber': weekNumber,
      'year': year,
      'photos': photos,
      'makeupFrequency': makeupFrequency,
      'makeupType': makeupType,
      'makeupRemoval': makeupRemoval,
      'cleansingFrequency': cleansingFrequency,
      'routineFollowed': routineFollowed,
      'spfThisWeek': spfThisWeek,
      'autoCorrection': autoCorrection,
      'reminderSent': reminderSent,
      'spfAlert': spfAlert,
    };
  }
}
