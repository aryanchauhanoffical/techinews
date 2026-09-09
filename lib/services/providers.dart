import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../data/models/article.dart';
import '../data/models/github_repo.dart';
import '../data/models/notification_item.dart';
import '../data/models/trending_topic.dart';
import '../data/local/local_store.dart';
import '../data/models/user.dart';
import '../data/repositories/api_article_repository.dart';
import '../data/repositories/api_notifications_repository.dart';
import '../data/repositories/api_trends_repository.dart';
import '../data/repositories/article_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/trends_repository.dart';
import 'pro.dart';

// ------- HTTP client -------
final dioProvider = Provider((ref) => buildDio());

/// Overridden in main() with the opened store. Throwing here makes a missing
/// override loud instead of silently losing saves.
final localStoreProvider = Provider<LocalStore>((_) => throw UnimplementedError('LocalStore not provided'));

// ------- Repositories -------
// Swap mock <-> live backend via `USE_MOCK_DATA` in .env.
bool _useMock() {
  final v = dotenv.maybeGet('USE_MOCK_DATA');
  return v == null || v.toLowerCase() == 'true';
}

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  if (_useMock()) return MockArticleRepository();
  return ApiArticleRepository(ref.watch(dioProvider), ref.watch(localStoreProvider));
});

final trendsRepositoryProvider = Provider<TrendsRepository>((ref) {
  if (_useMock()) return MockTrendsRepository();
  return ApiTrendsRepository(ref.watch(dioProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  if (_useMock()) return MockNotificationsRepository();
  return ApiNotificationsRepository(ref.watch(dioProvider), ref.watch(localStoreProvider));
});

// Use real Firebase auth when it's initialized and we're not in mock mode;
// otherwise fall back to the in-memory mock (desktop/web/tests).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_useMock() || Firebase.apps.isEmpty) return MockAuthRepository();
  return FirebaseAuthRepository(ref.watch(dioProvider));
});

// ------- User state -------
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AppUser?>(
  (ref) => CurrentUserNotifier(ref.watch(authRepositoryProvider), ref.watch(localStoreProvider)),
);

AppUser _guest(LocalStore store) => AppUser(
      id: 'guest',
      email: 'guest@techinews.app',
      displayName: 'Guest',
      interests: store.interests,
      notificationMode: store.notificationMode,
      createdAt: DateTime.now(),
    );

class CurrentUserNotifier extends StateNotifier<AppUser?> {
  CurrentUserNotifier(this._repo, this._store)
      : super(_store.onboardingComplete ? _guest(_store) : null) {
    _restore();
  }
  final AuthRepository _repo;
  final LocalStore _store;

  Future<void> _restore() async {
    final u = await _repo.currentUser();
    if (u != null) state = u.copyWith(interests: _store.interests, notificationMode: _store.notificationMode);
  }

  bool get isGuest => state == null || state!.id == 'guest';

  Future<void> signIn(AuthProvider provider, {String? email}) async {
    final u = await _repo.signIn(provider, email: email);
    state = u.copyWith(
      interests: u.interests.isEmpty ? _store.interests : u.interests,
      notificationMode: _store.notificationMode,
    );
    await _store.setOnboardingComplete(true);
  }

  Future<void> continueAsGuest() async {
    await _store.setOnboardingComplete(true);
    state = _guest(_store);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    await _store.setOnboardingComplete(false);
    state = null;
  }

  Future<void> setInterests(List<String> interests) async {
    await _store.setInterests(interests);
    await _store.setOnboardingComplete(true);
    if (state == null || state!.id == 'guest') {
      state = _guest(_store);
    } else {
      state = (await _repo.updateProfile(interests: interests)).copyWith(interests: interests);
    }
  }

  Future<void> setNotificationMode(NotificationMode mode) async {
    await _store.setNotificationMode(mode);
    if (state == null || state!.id == 'guest') {
      state = _guest(_store);
    } else {
      state = (await _repo.updateProfile(notificationMode: mode)).copyWith(notificationMode: mode);
    }
  }
}

/// Saved ids as reactive state so rows flip instantly; the repository owns
/// the persistence.
class SavedIdsNotifier extends StateNotifier<Set<String>> {
  SavedIdsNotifier(this._ref) : super(_ref.read(localStoreProvider).savedIds);
  final Ref _ref;

  /// Returns false when the free-tier limit blocks a new save.
  Future<bool> toggle(String id) async {
    final next = {...state};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (!_ref.read(isProProvider) && next.length >= ProNotifier.freeSaveLimit) return false;
      next.add(id);
    }
    state = next;
    await _ref.read(articleRepositoryProvider).toggleSave(id);
    _ref.invalidate(savedArticlesProvider);
    return true;
  }
}

final savedIdsProvider = StateNotifierProvider<SavedIdsNotifier, Set<String>>((ref) => SavedIdsNotifier(ref));

/// Last / next collector run, for the "updated · next" line on the feed.
final feedMetaProvider = FutureProvider.autoDispose<FeedMeta>((ref) async {
  if (_useMock()) {
    final now = DateTime.now();
    return FeedMeta(lastRun: now.subtract(const Duration(minutes: 14)), nextRun: now.add(const Duration(minutes: 46)), added: 37);
  }
  final r = await ref.watch(dioProvider).get('/api/v1/articles/meta');
  final j = r.data as Map<String, dynamic>;
  DateTime? p(String k) => j[k] == null ? null : DateTime.tryParse('${j[k]}Z')?.toLocal();
  return FeedMeta(lastRun: p('last_run'), nextRun: p('next_run'), added: (j['added'] ?? 0) as int);
});

class FeedMeta {
  final DateTime? lastRun;
  final DateTime? nextRun;
  final int added;
  const FeedMeta({this.lastRun, this.nextRun, this.added = 0});
}

/// Paginated feed. `feedProvider` keeps its old shape (AsyncValue of the
/// items loaded so far) so screens did not need to change; `loadMore()`
/// appends the next page.
class FeedState {
  final List<Article> items;
  final int nextPage;
  final bool hasMore;
  final bool loadingMore;
  const FeedState({this.items = const [], this.nextPage = 0, this.hasMore = true, this.loadingMore = false});
  FeedState copyWith({List<Article>? items, int? nextPage, bool? hasMore, bool? loadingMore}) => FeedState(
        items: items ?? this.items,
        nextPage: nextPage ?? this.nextPage,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class FeedNotifier extends StateNotifier<AsyncValue<FeedState>> {
  FeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load(reset: true);
  }
  final Ref _ref;
  static const _pageSize = 20;

  List<String> get _interests => _ref.read(currentUserProvider)?.interests ?? const [];

  Future<void> _load({required bool reset}) async {
    final current = state.valueOrNull ?? const FeedState();
    if (!reset && (!current.hasMore || current.loadingMore)) return;
    if (reset) {
      state = const AsyncValue.loading();
    } else {
      state = AsyncValue.data(current.copyWith(loadingMore: true));
    }
    try {
      final page = reset ? 0 : current.nextPage;
      final items = await _ref.read(articleRepositoryProvider).fetchFeed(page: page, pageSize: _pageSize, interests: _interests);
      final merged = reset ? items : [...current.items, ...items.where((a) => !current.items.any((b) => b.id == a.id))];
      state = AsyncValue.data(FeedState(items: merged, nextPage: page + 1, hasMore: items.length == _pageSize));
    } catch (e, st) {
      if (reset) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.data(current.copyWith(loadingMore: false));
      }
    }
  }

  Future<void> refresh() => _load(reset: true);
  Future<void> loadMore() => _load(reset: false);
}

final feedStateProvider = StateNotifierProvider.autoDispose<FeedNotifier, AsyncValue<FeedState>>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.interests));
  return FeedNotifier(ref);
});

final feedProvider = Provider.autoDispose<AsyncValue<List<Article>>>((ref) {
  return ref.watch(feedStateProvider).whenData((s) => s.items);
});

/// Other coverage of the same story, resolved from the lead's related ids.
final relatedArticlesProvider = FutureProvider.autoDispose.family<List<Article>, List<String>>((ref, ids) async {
  final repo = ref.watch(articleRepositoryProvider);
  final out = await Future.wait(ids.take(6).map(repo.fetchArticle));
  return out.whereType<Article>().toList();
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

/// Pro feature: keywords, companies, or repos the user wants a push for.
/// Stored on device; the push job reads them once account sync lands.
class TopicAlertsNotifier extends StateNotifier<List<String>> {
  TopicAlertsNotifier(this._store) : super(_store.topicAlerts);
  final LocalStore _store;

  Future<void> add(String term) async {
    final t = term.trim();
    if (t.isEmpty || state.any((x) => x.toLowerCase() == t.toLowerCase())) return;
    state = [...state, t];
    await _store.setTopicAlerts(state);
  }

  Future<void> remove(String term) async {
    state = state.where((x) => x != term).toList();
    await _store.setTopicAlerts(state);
  }
}

final topicAlertsProvider = StateNotifierProvider<TopicAlertsNotifier, List<String>>(
  (ref) => TopicAlertsNotifier(ref.watch(localStoreProvider)),
);
