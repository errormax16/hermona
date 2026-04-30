import '../../domain/entities/user_profile.dart';
import '../services/questionnaire_service.dart';

class UserRepository {
  final QuestionnaireService _service = QuestionnaireService();

  Future<UserProfile?> getUserProfile(String userId) async {
    return await _service.fetchUserProfile(userId);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _service.saveUserProfile(profile);
  }
}