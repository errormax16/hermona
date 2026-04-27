// ─────────────────────────────────────────────────────────────────────────────
// AppConstants – toutes les constantes de l'application
// ─────────────────────────────────────────────────────────────────────────────
class AppConstants {
  // ── Backend Python ──────────────────────────────────────────────────────────
  /// URL de base de votre API Python.
  /// Changez cette valeur quand votre backend est déployé.
  static const String apiBaseUrl = 'http://localhost:8000';

  // ── Appwrite ────────────────────────────────────────────────────────────────
  static const String appwriteEndpoint  = 'https://cloud.appwrite.io/v1';
  static const String appwriteProjectId = 'YOUR_APPWRITE_PROJECT_ID';
  static const String appwriteBucketId  = 'YOUR_BUCKET_ID';

  // ── Firestore Collections ───────────────────────────────────────────────────
  static const String colUsers           = 'users';
  static const String colDetections      = 'detections';
  static const String colRecommendations = 'recommendations';
  static const String colPredictions     = 'predictions';
  static const String colChatHistory     = 'chat_history';
  static const String colForumPosts      = 'forum_posts';
  static const String colForumReplies    = 'forum_replies';
  static const String colConversations   = 'conversations';
  static const String colMessages        = 'messages';
  static const String colLikes           = 'likes';
  static const String colReports         = 'reports';

  // ── SharedPreferences Keys ──────────────────────────────────────────────────
  static const String keyThemeMode     = 'theme_mode';
  static const String keyPrimaryColor  = 'primary_color';
  static const String keyWelcomeShown  = 'welcome_shown';

  // ── Forum Categories ────────────────────────────────────────────────────────
  static const List<String> forumCategories = [
    'Général', 'Routine beauté', 'Alimentation',
    'Hormones', 'Traitements', 'Témoignages', 'Questions',
  ];

  // ── Photo tips ──────────────────────────────────────────────────────────────
  static const String photoTipsGood =
      '✅ Lumière naturelle douce\n'
      '✅ Visage propre, sans maquillage\n'
      '✅ Photo nette, distance 20-30 cm\n'
      '✅ Fond neutre';

  static const String photoTipsBad =
      '❌ Pas de filtres ni retouches\n'
      '❌ Pas de flash direct\n'
      '❌ Pas de lunettes\n'
      '❌ Éviter le mauvais éclairage';
}
