import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/article/presentation/article_detail_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/saved_screen.dart';
import '../features/pro/presentation/paywall_screen.dart';
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
  static const notifications = '/inbox';
  static const profile = '/profile';
  static const saved = '/saved';
  static const settings = '/profile/settings';
  static const pro = '/pro';
  static const article = '/article/:id';
  static String articlePath(String id) => '/article/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.feed, pageBuilder: (_, _) => const NoTransitionPage(child: FeedScreen())),
          GoRoute(path: AppRoutes.discover, pageBuilder: (_, _) => const NoTransitionPage(child: DiscoverScreen())),
          GoRoute(path: AppRoutes.saved, pageBuilder: (_, _) => const NoTransitionPage(child: SavedScreen())),
          GoRoute(path: AppRoutes.profile, pageBuilder: (_, _) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
      GoRoute(path: AppRoutes.search, builder: (_, state) => SearchScreen(initialQuery: state.uri.queryParameters['q'])),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: AppRoutes.pro, builder: (_, _) => const PaywallScreen()),
      GoRoute(
        path: AppRoutes.article,
        builder: (context, state) => ArticleDetailScreen(articleId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('That page does not exist.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.feed),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('Back to the feed'),
            ),
          ],
        ),
      ),
    ),
  );
});
