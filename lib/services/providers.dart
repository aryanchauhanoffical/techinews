import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../data/models/article.dart';
import '../data/models/github_repo.dart';
import '../data/models/notification_item.dart';
import '../data/models/trending_topic.dart';
import '../data/models/user.dart';
import '../data/repositories/api_article_repository.dart';
import '../data/repositories/article_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/trends_repository.dart';

// ------- HTTP client -------
final dioProvider = Provider((ref) => buildDio());

// ------- Repositories -------
// Swap mock <-> live backend via `USE_MOCK_DATA` in .env.
bool _useMock() {
  final v = dotenv.maybeGet('USE_MOCK_DATA');
  return v == null || v.toLowerCase() == 'true';
}

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  if (_useMock()) return MockArticleRepository();
  return ApiArticleRepository(ref.watch(dioProvider));
});

final trendsRepositoryProvider = Provider<TrendsRepository>(
  (ref) => MockTrendsRepository(),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => MockNotificationsRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

// ------- User state -------
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AppUser?>(
  (ref) => CurrentUserNotifier(ref.watch(authRepositoryProvider)),
);

class CurrentUserNotifier extends StateNotifier<AppUser?> {
  CurrentUserNotifier(this._repo) : super(null);
  final AuthRepository _repo;

  Future<void> signIn(AuthProvider provider, {String? email}) async {
    state = await _repo.signIn(provider, email: email);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = null;
  }

  Future<void> setInterests(List<String> interests) async {
    if (state == null) {
      state = AppUser(
        id: 'guest',
        email: 'guest@techinews.app',
        displayName: 'Guest',
        interests: interests,
        createdAt: DateTime.now(),
      );
    } else {
      state = await _repo.updateProfile(interests: interests);
    }
  }

  Future<void> setNotificationMode(NotificationMode mode) async {
    if (state != null) {
      state = await _repo.updateProfile(notificationMode: mode);
    }
  }
}

// ------- Feed -------
final feedProvider = FutureProvider.autoDispose<List<Article>>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repo.fetchFeed(interests: user?.interests ?? const []);
});

final articleProvider =
    FutureProvider.autoDispose.family<Article?, String>((ref, id) {
  return ref.watch(articleRepositoryProvider).fetchArticle(id);
});

final savedArticlesProvider = FutureProvider.autoDispose<List<Article>>(
  (ref) => ref.watch(articleRepositoryProvider).saved(),
);

// ------- Search -------
final searchQueryProvider = StateProvider<String>((_) => '');
final searchResultsProvider = FutureProvider.autoDispose<List<Article>>(
  (ref) {
    final q = ref.watch(searchQueryProvider);
    return ref.watch(articleRepositoryProvider).search(q);
  },
);

// ------- Trends -------
final trendingTopicsProvider = FutureProvider.autoDispose<List<TrendingTopic>>(
  (ref) => ref.watch(trendsRepositoryProvider).trendingTopics(),
);

final trendingReposProvider = FutureProvider.autoDispose<List<GithubRepo>>(
  (ref) => ref.watch(trendsRepositoryProvider).trendingRepos(),
);

final fundingEventsProvider = FutureProvider.autoDispose<List<FundingEvent>>(
  (ref) => ref.watch(trendsRepositoryProvider).fundingEvents(),
);

// ------- Notifications -------
final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationItem>>(
  (ref) => ref.watch(notificationsRepositoryProvider).list(),
);

// ------- Theme -------
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.dark);
