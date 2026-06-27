import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/article/presentation/article_detail_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/saved_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/shell/main_shell.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const feed = '/feed';
  static const discover = '/discover';
  static const search = '/search';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const saved = '/profile/saved';
  static const settings = '/profile/settings';
  static const article = '/article/:id';

  static String articlePath(String id) => '/article/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.feed,
            pageBuilder: (_, __) => const NoTransitionPage(child: FeedScreen()),
          ),
          GoRoute(
            path: AppRoutes.discover,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DiscoverScreen()),
          ),
          GoRoute(
            path: AppRoutes.search,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.saved,
        builder: (_, __) => const SavedScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.article,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ArticleDetailScreen(articleId: id);
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
