import 'package:dio/dio.dart';

import '../models/github_repo.dart';
import '../models/trending_topic.dart';
import 'trends_repository.dart';

/// Discover data from the backend, all derived from stored articles.
class ApiTrendsRepository implements TrendsRepository {
  ApiTrendsRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<TrendingTopic>> trendingTopics() async {
    final r = await _dio.get('/api/v1/trends/topics');
    return (r.data as List).cast<Map<String, dynamic>>().map((j) => TrendingTopic(
          id: j['id'] as String,
          name: j['name'] as String,
          description: (j['description'] ?? '') as String,
          articleCount: (j['article_count'] ?? 0) as int,
          growthPercent: ((j['growth_percent'] ?? 0) as num).toDouble(),
        )).toList();
  }

  @override
  Future<List<GithubRepo>> trendingRepos() async {
    final r = await _dio.get('/api/v1/trends/repos');
    return (r.data as List).cast<Map<String, dynamic>>().map(repoFromJson).toList();
  }

  @override
  Future<List<FundingEvent>> fundingEvents() async {
    final r = await _dio.get('/api/v1/trends/funding');
    return (r.data as List).cast<Map<String, dynamic>>().map((j) => FundingEvent(
          id: j['id'] as String,
          companyName: j['company_name'] as String,
          round: (j['round'] ?? 'Round') as String,
          amountUsd: ((j['amount_usd'] ?? 0) as num).toDouble(),
          investors: ((j['investors'] ?? const []) as List).cast<String>(),
          description: j['description'] as String?,
          announcedAt: DateTime.tryParse((j['announced_at'] ?? '') as String) ?? DateTime.now(),
        )).toList();
  }
}

GithubRepo repoFromJson(Map<String, dynamic> j) => GithubRepo(
      id: j['id'] as String,
      fullName: j['full_name'] as String,
      description: (j['description'] ?? '') as String,
      url: j['url'] as String,
      language: j['language'] as String?,
      stars: (j['stars'] ?? 0) as int,
      forks: (j['forks'] ?? 0) as int,
      starsThisWeek: (j['stars_this_week'] ?? 0) as int,
      readmeExcerpt: j['readme_excerpt'] as String?,
      lastCommit: j['last_commit'] == null ? null : DateTime.tryParse(j['last_commit'] as String),
    );
