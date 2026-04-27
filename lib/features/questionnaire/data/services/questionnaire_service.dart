import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/daily_survey.dart';
import '../../domain/entities/weekly_survey.dart';

class QuestionnaireService {
  final _db = FirebaseFirestore.instance;

  // Profil utilisateur
  Future<UserProfile?> fetchUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(doc.data()!, doc.id);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.id).set(profile.toJson());
  }

  // Questionnaire quotidien
  Future<DailySurvey?> fetchDailySurvey(String userId, DateTime date) async {
    final id = '${userId}_${date.toIso8601String().substring(0,10)}';
    final doc = await _db.collection('daily_surveys').doc(id).get();
    if (!doc.exists) return null;
    return DailySurvey.fromJson(doc.data()!, doc.id);
  }

  Future<void> saveDailySurvey(DailySurvey survey) async {
    await _db.collection('daily_surveys').doc(survey.id).set(survey.toJson());
  }

  // Questionnaire hebdomadaire
  Future<WeeklySurvey?> fetchWeeklySurvey(String userId, int weekNumber, int year) async {
    final id = '${userId}_${weekNumber}_$year';
    final doc = await _db.collection('weekly_surveys').doc(id).get();
    if (!doc.exists) return null;
    return WeeklySurvey.fromJson(doc.data()!, doc.id);
  }

  Future<void> saveWeeklySurvey(WeeklySurvey survey) async {
    await _db.collection('weekly_surveys').doc(survey.id).set(survey.toJson());
  }
}
