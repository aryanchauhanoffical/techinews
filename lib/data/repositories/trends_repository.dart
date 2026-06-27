import '../mock/mock_trends.dart';
import '../models/github_repo.dart';
import '../models/trending_topic.dart';

abstract class TrendsRepository {
  Future<List<TrendingTopic>> trendingTopics();
  Future<List<GithubRepo>> trendingRepos();
  Future<List<FundingEvent>> fundingEvents();
}

class MockTrendsRepository implements TrendsRepository {
  @override
  Future<List<TrendingTopic>> trendingTopics() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockTrends.topics;
  }

  @override
  Future<List<GithubRepo>> trendingRepos() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockTrends.trendingRepos;
  }

  @override
  Future<List<FundingEvent>> fundingEvents() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockTrends.fundingEvents;
  }
}
