import '../mock/mock_articles.dart';
import '../models/article.dart';

abstract class ArticleRepository {
  Future<List<Article>> fetchFeed({
    int page = 0,
    int pageSize = 20,
    List<String> interests = const [],
  });
  Future<Article?> fetchArticle(String id);
  Future<List<Article>> search(String query, {List<String> filters = const []});
  Future<List<Article>> saved();
  Future<void> toggleSave(String articleId);
  Future<void> markRead(String articleId);
}

class MockArticleRepository implements ArticleRepository {
  final Map<String, Article> _articles = {
    for (final a in MockArticles.all) a.id: a,
  };
  final Set<String> _saved = {};
  final Set<String> _read = {};

  @override
  Future<List<Article>> fetchFeed({
    int page = 0,
    int pageSize = 20,
    List<String> interests = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final filtered = _articles.values.where((a) {
      if (interests.isEmpty) return true;
      return a.topics.any((t) => interests
              .any((i) => i.toLowerCase().contains(t.toLowerCase()))) ||
          a.companies.any((c) => interests
              .any((i) => i.toLowerCase().contains(c.toLowerCase())));
    }).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final start = page * pageSize;
    if (start >= filtered.length) return [];
    return filtered
        .sublist(start, (start + pageSize).clamp(0, filtered.length))
        .map(_decorate)
        .toList();
  }

  @override
  Future<Article?> fetchArticle(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final a = _articles[id];
    return a == null ? null : _decorate(a);
  }

  @override
  Future<List<Article>> search(String query,
      {List<String> filters = const []}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _articles.values
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            (a.summary?.toLowerCase().contains(q) ?? false) ||
            a.topics.any((t) => t.toLowerCase().contains(q)) ||
            a.companies.any((c) => c.toLowerCase().contains(q)))
        .map(_decorate)
        .toList();
  }

  @override
  Future<List<Article>> saved() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _saved.map((id) => _articles[id]).whereType<Article>().map(_decorate).toList();
  }

  @override
  Future<void> toggleSave(String articleId) async {
    if (_saved.contains(articleId)) {
      _saved.remove(articleId);
    } else {
      _saved.add(articleId);
    }
  }

  @override
  Future<void> markRead(String articleId) async {
    _read.add(articleId);
  }

  Article _decorate(Article a) => a.copyWith(
        isSaved: _saved.contains(a.id),
        isRead: _read.contains(a.id),
      );
}
