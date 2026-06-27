import 'package:equatable/equatable.dart';

import 'github_repo.dart';
import 'social_post.dart';

enum ArticleSourceType { news, blog, hackerNews, reddit, productHunt, github }

class ArticleSource extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;
  final ArticleSourceType type;

  const ArticleSource({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.type,
  });

  @override
  List<Object?> get props => [id, name, iconUrl, type];
}

class Article extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final String? body;
  final String? imageUrl;
  final String url;
  final ArticleSource source;
  final String? author;
  final DateTime publishedAt;
  final List<String> topics;
  final List<String> companies;
  final List<String> stack;
  final int trendScore;
  final int viralityScore;
  final String? whyItMatters;
  final List<String> keyPoints;
  final List<GithubRepo> relatedRepos;
  final List<SocialPost> discussions;
  final bool isSaved;
  final bool isRead;

  const Article({
    required this.id,
    required this.title,
    this.summary,
    this.body,
    this.imageUrl,
    required this.url,
    required this.source,
    this.author,
    required this.publishedAt,
    this.topics = const [],
    this.companies = const [],
    this.stack = const [],
    this.trendScore = 0,
    this.viralityScore = 0,
    this.whyItMatters,
    this.keyPoints = const [],
    this.relatedRepos = const [],
    this.discussions = const [],
    this.isSaved = false,
    this.isRead = false,
  });

  Article copyWith({
    bool? isSaved,
    bool? isRead,
    String? summary,
    List<String>? keyPoints,
    String? whyItMatters,
    List<GithubRepo>? relatedRepos,
    List<SocialPost>? discussions,
  }) {
    return Article(
      id: id,
      title: title,
      summary: summary ?? this.summary,
      body: body,
      imageUrl: imageUrl,
      url: url,
      source: source,
      author: author,
      publishedAt: publishedAt,
      topics: topics,
      companies: companies,
      stack: stack,
      trendScore: trendScore,
      viralityScore: viralityScore,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      keyPoints: keyPoints ?? this.keyPoints,
      relatedRepos: relatedRepos ?? this.relatedRepos,
      discussions: discussions ?? this.discussions,
      isSaved: isSaved ?? this.isSaved,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, isSaved, isRead];
}
