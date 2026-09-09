import 'package:dio/dio.dart';

import '../local/local_store.dart';

import '../models/article.dart';
import '../models/github_repo.dart';
import '../models/social_post.dart';
import 'article_repository.dart';

/// HTTP-backed ArticleRepository — talks to the FastAPI backend.
class ApiArticleRepository implements ArticleRepository {
  ApiArticleRepository(this._dio, this._store);
  final Dio _dio;
  final LocalStore _store;

  /// Raw JSON of every article seen this session, so a save can be cached
  /// locally without a second request.
  final Map<String, Map<String, dynamic>> _raw = {};

  @override
  Future<List<Article>> fetchFeed({
    int page = 0,
    int pageSize = 20,
    List<String> interests = const [],
  }) async {
    final r = await _dio.get(
      '/api/v1/articles/feed',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (interests.isNotEmpty) 'interests': interests,
      },
    );
    final items = (r.data['items'] as List).cast<Map<String, dynamic>>();
    for (final j in items) {
      _raw[j['id'] as String] = j;
    }
    return items.map(_articleFromJson).map(_decorate).toList();
  }

  @override
  Future<Article?> fetchArticle(String id) async {
    try {
      final r = await _dio.get('/api/v1/articles/$id');
      final j = r.data as Map<String, dynamic>;
      _raw[id] = j;
      return _decorate(_articleFromJson(j));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Article>> search(String query, {List<String> filters = const []}) async {
    if (query.trim().isEmpty) return [];
    final r = await _dio.get('/api/v1/articles/search', queryParameters: {'q': query});
    return (r.data as List)
        .cast<Map<String, dynamic>>()
        .map(_articleFromJson)
        .map(_decorate)
        .toList();
  }

  @override
  Future<List<Article>> saved() async {
    final ids = _store.savedIds;
    if (ids.isEmpty) return [];
    final out = <Article>[];
    for (final id in ids) {
      final cached = _store.cachedArticle(id) ?? _raw[id];
      if (cached != null) {
        out.add(_decorate(_articleFromJson(cached)));
        continue;
      }
      final a = await fetchArticle(id);
      if (a != null) out.add(a);
    }
    out.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return out;
  }

  @override
  Future<void> toggleSave(String articleId) async {
    final ids = _store.savedIds;
    if (ids.remove(articleId)) {
      await _store.dropArticle(articleId);
    } else {
      ids.add(articleId);
      final j = _raw[articleId];
      if (j != null) await _store.cacheArticle(articleId, j);
    }
    await _store.setSaved(ids);
  }

  @override
  Future<void> markRead(String articleId) async {
    final ids = _store.readIds..add(articleId);
    await _store.setRead(ids);
  }

  Article _decorate(Article a) =>
      a.copyWith(isSaved: _store.savedIds.contains(a.id), isRead: _store.readIds.contains(a.id));
}

// ---------- JSON mapping (backend snake_case → Flutter camelCase) ----------

Article _articleFromJson(Map<String, dynamic> j) {
  return Article(
    id: j['id'] as String,
    title: j['title'] as String,
    summary: j['summary'] as String?,
    body: j['body'] as String?,
    imageUrl: j['image_url'] as String?,
    url: j['url'] as String,
    source: _sourceFromJson(j['source'] as Map<String, dynamic>),
    author: j['author'] as String?,
    publishedAt: DateTime.parse(j['published_at'] as String),
    topics: ((j['topics'] as List?) ?? const []).cast<String>(),
    companies: ((j['companies'] as List?) ?? const []).cast<String>(),
    stack: ((j['stack'] as List?) ?? const []).cast<String>(),
    trendScore: (j['trend_score'] as num?)?.toInt() ?? 0,
    coverage: (j['coverage'] as num?)?.toInt() ?? 1,
    relatedIds: ((j['related_ids'] as List?) ?? const []).cast<String>(),
    viralityScore: (j['virality_score'] as num?)?.toInt() ?? 0,
    whyItMatters: j['why_it_matters'] as String?,
    keyPoints: ((j['key_points'] as List?) ?? const []).cast<String>(),
    relatedRepos: ((j['related_repos'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_repoFromJson)
        .toList(),
    discussions: ((j['discussions'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_postFromJson)
        .toList(),
  );
}

ArticleSource _sourceFromJson(Map<String, dynamic> j) {
  return ArticleSource(
    id: j['id'] as String,
    name: j['name'] as String,
    iconUrl: j['icon_url'] as String?,
    type: _sourceType((j['type'] as String?) ?? 'news'),
  );
}

ArticleSourceType _sourceType(String s) {
  switch (s) {
    case 'blog':
      return ArticleSourceType.blog;
    case 'hacker_news':
      return ArticleSourceType.hackerNews;
    case 'reddit':
      return ArticleSourceType.reddit;
    case 'youtube':
      return ArticleSourceType.youtube;
    case 'bluesky':
      return ArticleSourceType.bluesky;
    case 'product_hunt':
      return ArticleSourceType.productHunt;
    case 'github':
      return ArticleSourceType.github;
    default:
      return ArticleSourceType.news;
  }
}

GithubRepo _repoFromJson(Map<String, dynamic> j) {
  return GithubRepo(
    id: j['id'] as String,
    fullName: j['full_name'] as String,
    description: (j['description'] as String?) ?? '',
    url: j['url'] as String,
    language: j['language'] as String?,
    stars: (j['stars'] as num?)?.toInt() ?? 0,
    forks: (j['forks'] as num?)?.toInt() ?? 0,
    starsThisWeek: (j['stars_this_week'] as num?)?.toInt() ?? 0,
    readmeExcerpt: j['readme_excerpt'] as String?,
    hook: j['hook'] as String?,
    pitch: j['pitch'] as String?,
    altTo: j['alt_to'] as String?,
    lastCommit: j['last_commit'] != null
        ? DateTime.tryParse(j['last_commit'] as String)
        : null,
  );
}

SocialPost _postFromJson(Map<String, dynamic> j) {
  return SocialPost(
    id: j['id'] as String,
    platform: _platform((j['platform'] as String?) ?? 'reddit'),
    author: (j['author'] as String?) ?? 'anonymous',
    authorHandle: j['author_handle'] as String?,
    content: (j['content'] as String?) ?? '',
    url: j['url'] as String,
    upvotes: (j['upvotes'] as num?)?.toInt() ?? 0,
    comments: (j['comments'] as num?)?.toInt() ?? 0,
    postedAt: DateTime.parse(j['posted_at'] as String),
    sentiment: (j['sentiment'] as String?) ?? 'neutral',
  );
}

SocialPlatform _platform(String s) {
  switch (s) {
    case 'twitter':
      return SocialPlatform.twitter;
    case 'hacker_news':
      return SocialPlatform.hackerNews;
    default:
      return SocialPlatform.reddit;
  }
}
