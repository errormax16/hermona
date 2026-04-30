import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/terms_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/detection/presentation/screens/detection_result_screen.dart';
import '../../features/recommendation/presentation/screens/recommendation_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/prediction/presentation/screens/prediction_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/history_screen.dart';
import '../../features/forum/presentation/screens/forum_screen.dart';
import '../../features/forum/presentation/screens/forum_detail_screen.dart';
import '../../features/forum/presentation/screens/create_post_screen.dart';
import '../../features/messaging/presentation/screens/conversations_screen.dart';
import '../../features/messaging/presentation/screens/chat_private_screen.dart';
import '../../features/questionnaire/presentation/screens/profile_questionnaire_screen.dart';
import '../../features/questionnaire/presentation/screens/daily_questionnaire_screen.dart';
import '../../features/questionnaire/presentation/screens/weekly_questionnaire_screen.dart';
import '../widgets/main_scaffold.dart';

final _rootKey  = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/welcome',
  redirect: (context, state) {
    final authed = FirebaseAuth.instance.currentUser != null;
    final isAuth = state.matchedLocation.startsWith('/welcome') ||
                   state.matchedLocation.startsWith('/login') ||
                   state.matchedLocation.startsWith('/register') ||
                   state.matchedLocation.startsWith('/terms');
    if (!authed && !isAuth) return '/welcome';
    if (authed  &&  isAuth) return '/home';
    return null;
  },
  routes: [
    // ── Auth (pas de shell) ────────────────────────────────────────────────
    GoRoute(path: '/welcome',  builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/terms',    builder: (_, __) => const TermsScreen()),

    // ── Shell (bottom nav) ─────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (_, __, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home',       builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/chat',       builder: (_, __) => const ChatScreen()),
        GoRoute(path: '/prediction', builder: (_, __) => const PredictionScreen()),
        GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Feature routes (full-screen) ───────────────────────────────────────
    GoRoute(
      path: '/detection/result',
      builder: (_, state) => DetectionResultScreen(
        data: state.extra as Map<String, dynamic>,
      ),
    ),
    GoRoute(
      path: '/recommendation/:detectionId',
      builder: (_, state) => RecommendationScreen(
        detectionId: state.pathParameters['detectionId']!,
        detectionData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(path: '/history',       builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/forum',         builder: (_, __) => const ForumScreen()),
    GoRoute(
      path: '/forum/create',
      builder: (_, __) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/forum/:id',
      builder: (_, state) => ForumDetailScreen(postId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/messages',      builder: (_, __) => const ConversationsScreen()),
    GoRoute(
      path: '/messages/:convId',
      builder: (_, state) => ChatPrivateScreen(
        conversationId: state.pathParameters['convId']!,
      ),
    ),
    GoRoute(path: '/onboarding',    builder: (_, __) => const ProfileQuestionnaireScreen()),
    GoRoute(path: '/daily-survey',  builder: (_, __) => const DailyQuestionnaireScreen()),
    GoRoute(path: '/weekly-survey', builder: (_, __) => const WeeklyQuestionnaireScreen()),
  ],
);
