import '../models/article.dart';

class MockSources {
  MockSources._();

  static const techCrunch = ArticleSource(
    id: 'src_techcrunch',
    name: 'TechCrunch',
    iconUrl: 'https://techcrunch.com/wp-content/uploads/2015/02/cropped-cropped-favicon-gradient.png',
    type: ArticleSourceType.news,
  );

  static const theVerge = ArticleSource(
    id: 'src_verge',
    name: 'The Verge',
    type: ArticleSourceType.news,
  );

  static const hackerNews = ArticleSource(
    id: 'src_hn',
    name: 'Hacker News',
    type: ArticleSourceType.hackerNews,
  );

  static const openAiBlog = ArticleSource(
    id: 'src_openai',
    name: 'OpenAI Blog',
    type: ArticleSourceType.blog,
  );

  static const anthropicBlog = ArticleSource(
    id: 'src_anthropic',
    name: 'Anthropic',
    type: ArticleSourceType.blog,
  );

  static const githubTrending = ArticleSource(
    id: 'src_gh_trending',
    name: 'GitHub Trending',
    type: ArticleSourceType.github,
  );

  static const redditML = ArticleSource(
    id: 'src_reddit_ml',
    name: 'r/MachineLearning',
    type: ArticleSourceType.reddit,
  );

  static const productHunt = ArticleSource(
    id: 'src_ph',
    name: 'Product Hunt',
    type: ArticleSourceType.productHunt,
  );

  static const arsTechnica = ArticleSource(
    id: 'src_ars',
    name: 'Ars Technica',
    type: ArticleSourceType.news,
  );
}
