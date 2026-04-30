import '../../domain/entities/daily_survey.dart';
import '../../domain/entities/weekly_survey.dart';
import '../services/questionnaire_service.dart';

class SurveyRepository {
  final QuestionnaireService _service = QuestionnaireService();

  // ===== DAILY =====

  Future<DailySurvey?> getDailySurvey(String userId, DateTime date) async {
    return await _service.fetchDailySurvey(userId, date);
  }

  Future<void> saveDailySurvey(DailySurvey survey) async {
    await _service.saveDailySurvey(survey);
  }

  // ===== WEEKLY =====

  Future<WeeklySurvey?> getWeeklySurvey(
      String userId, int weekNumber, int year) async {
    return await _service.fetchWeeklySurvey(userId, weekNumber, year);
  }

  Future<void> saveWeeklySurvey(WeeklySurvey survey) async {
    await _service.saveWeeklySurvey(survey);
  }
}