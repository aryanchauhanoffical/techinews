import '../models/github_repo.dart';
import '../models/trending_topic.dart';

class MockTrends {
  MockTrends._();

  static DateTime _daysAgo(int d) =>
      DateTime.now().subtract(Duration(days: d));

  static final List<TrendingTopic> topics = [
    const TrendingTopic(
      id: 't1',
      name: 'GPT-5.5',
      description: '10M context + agentic tools',
      articleCount: 142,
      growthPercent: 1840,
    ),
    const TrendingTopic(
      id: 't2',
      name: 'Llama 4',
      description: 'Open 405B with commercial license',
      articleCount: 98,
      growthPercent: 920,
    ),
    const TrendingTopic(
      id: 't3',
      name: 'Rust in Kernel',
      description: 'Async runtime in mainline 6.13',
      articleCount: 64,
      growthPercent: 412,
    ),
    const TrendingTopic(
      id: 't4',
      name: 'On-device AI',
      description: 'Apple, Google, Qualcomm racing',
      articleCount: 87,
      growthPercent: 285,
    ),
    const TrendingTopic(
      id: 't5',
      name: 'Anthropic Funding',
      description: '\$8B Series F, \$200B valuation',
      articleCount: 53,
      growthPercent: 654,
    ),
    const TrendingTopic(
      id: 't6',
      name: 'Bun 1.5',
      description: 'Native RSC, 4x faster builds',
      articleCount: 41,
      growthPercent: 312,
    ),
  ];

  static final List<GithubRepo> trendingRepos = [
    GithubRepo(
      id: 'tr1',
      fullName: 'meta-llama/llama4',
      description: 'Reference implementation for Llama 4',
      url: 'https://github.com/meta-llama/llama4',
      language: 'Python',
      stars: 14200,
      forks: 1840,
      starsThisWeek: 8920,
      lastCommit: _daysAgo(1),
    ),
    GithubRepo(
      id: 'tr2',
      fullName: 'oven-sh/bun',
      description:
          'Incredibly fast JavaScript runtime, bundler, transpiler and package manager',
      url: 'https://github.com/oven-sh/bun',
      language: 'Zig',
      stars: 82400,
      forks: 3120,
      starsThisWeek: 2840,
      lastCommit: _daysAgo(0),
    ),
    GithubRepo(
      id: 'tr3',
      fullName: 'anthropics/claude-code',
      description: 'Anthropic\'s official CLI for Claude',
      url: 'https://github.com/anthropics/claude-code',
      language: 'TypeScript',
      stars: 21300,
      forks: 1240,
      starsThisWeek: 2120,
      lastCommit: _daysAgo(0),
    ),
    GithubRepo(
      id: 'tr4',
      fullName: 'modular/mojo',
      description: 'The Mojo Programming Language',
      url: 'https://github.com/modular/mojo',
      language: 'Mojo',
      stars: 23100,
      forks: 2840,
      starsThisWeek: 1780,
      lastCommit: _daysAgo(1),
    ),
    GithubRepo(
      id: 'tr5',
      fullName: 'huggingface/transformers',
      description: 'State-of-the-art ML for PyTorch, TensorFlow, and JAX',
      url: 'https://github.com/huggingface/transformers',
      language: 'Python',
      stars: 132000,
      forks: 26400,
      starsThisWeek: 1420,
      lastCommit: _daysAgo(0),
    ),
    GithubRepo(
      id: 'tr6',
      fullName: 'denoland/deno',
      description: 'A modern runtime for JavaScript and TypeScript',
      url: 'https://github.com/denoland/deno',
      language: 'Rust',
      stars: 95800,
      forks: 5320,
      starsThisWeek: 1180,
      lastCommit: _daysAgo(0),
    ),
  ];

  static final List<FundingEvent> fundingEvents = [
    FundingEvent(
      id: 'f1',
      companyName: 'Anthropic',
      round: 'Series F',
      amountUsd: 8000000000,
      investors: ['Google', 'Mubadala', 'Lightspeed', 'Spark', 'Bessemer'],
      description: 'Push Claude into enterprise; \$5B earmarked for compute.',
      announcedAt: _daysAgo(0),
    ),
    FundingEvent(
      id: 'f2',
      companyName: 'Lovable',
      round: 'Series B',
      amountUsd: 200000000,
      investors: ['Accel', 'Index Ventures'],
      description: 'AI app builder hits 1M devs, raises at \$2B valuation.',
      announcedAt: _daysAgo(1),
    ),
    FundingEvent(
      id: 'f3',
      companyName: 'Cursor (Anysphere)',
      round: 'Series C',
      amountUsd: 500000000,
      investors: ['Thrive Capital', 'Andreessen Horowitz'],
      description: '\$9B valuation as AI IDE crosses \$200M ARR.',
      announcedAt: _daysAgo(3),
    ),
    FundingEvent(
      id: 'f4',
      companyName: 'Mistral',
      round: 'Series C',
      amountUsd: 1500000000,
      investors: ['General Catalyst', 'Lightspeed'],
      description: 'European LLM lab raises at \$10B valuation.',
      announcedAt: _daysAgo(5),
    ),
  ];
}
