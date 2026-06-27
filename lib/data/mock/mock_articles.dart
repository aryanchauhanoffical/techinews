import '../models/article.dart';
import '../models/github_repo.dart';
import '../models/social_post.dart';
import 'mock_sources.dart';

class MockArticles {
  MockArticles._();

  static DateTime _hoursAgo(int h) =>
      DateTime.now().subtract(Duration(hours: h));

  static final List<Article> all = [
    Article(
      id: 'a1',
      title:
          'OpenAI launches GPT-5.5 with native agentic reasoning and unlimited tool use',
      summary:
          'GPT-5.5 introduces persistent memory across sessions, native browser and code execution, and a 10M-token context window — pricing drops 40% vs GPT-5.',
      imageUrl:
          'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=1200',
      url: 'https://openai.com/blog/gpt-5-5',
      source: MockSources.openAiBlog,
      author: 'OpenAI Team',
      publishedAt: _hoursAgo(2),
      topics: ['AI', 'OpenAI'],
      companies: ['OpenAI'],
      stack: ['LLM', 'Python', 'API'],
      trendScore: 98,
      viralityScore: 94,
      whyItMatters:
          'The 10M-token context unlocks entire codebases as input. The 40% price cut pressures Anthropic and Google to respond. Agentic tool use being native means existing wrapper frameworks (LangChain, AutoGPT) lose most of their reason to exist.',
      keyPoints: [
        'Persistent memory across sessions — no more re-priming with context',
        '10M-token context window (5x previous max)',
        'Native browser, code, and shell execution built into the API',
        'Pricing: \$2.50 / \$10 per million input/output tokens — 40% drop',
        'Available to Plus and API users today; Enterprise tier next week',
      ],
      relatedRepos: [
        const GithubRepo(
          id: 'r1',
          fullName: 'openai/openai-cookbook',
          description: 'Examples and guides for using the OpenAI API',
          url: 'https://github.com/openai/openai-cookbook',
          language: 'Jupyter Notebook',
          stars: 62100,
          forks: 9800,
          starsThisWeek: 1240,
        ),
        const GithubRepo(
          id: 'r2',
          fullName: 'openai/openai-python',
          description: 'The official Python library for the OpenAI API',
          url: 'https://github.com/openai/openai-python',
          language: 'Python',
          stars: 22400,
          forks: 3100,
          starsThisWeek: 680,
        ),
      ],
      discussions: [
        SocialPost(
          id: 's1',
          platform: SocialPlatform.hackerNews,
          author: 'patio11',
          content:
              '10M tokens is the real story. Every "agentic framework" that exists to chunk and route context just became a much harder sell.',
          url: 'https://news.ycombinator.com/item?id=123',
          upvotes: 1842,
          comments: 643,
          postedAt: _hoursAgo(1),
          sentiment: 'positive',
        ),
        SocialPost(
          id: 's2',
          platform: SocialPlatform.twitter,
          author: 'swyx',
          authorHandle: '@swyx',
          content:
              'GPT-5.5 pricing is a declaration of war. \$2.50/M input is below Gemini Flash. Anthropic needs to ship Sonnet 5 fast.',
          url: 'https://x.com/swyx/status/123',
          upvotes: 4231,
          comments: 287,
          postedAt: _hoursAgo(1),
          sentiment: 'positive',
        ),
      ],
    ),
    Article(
      id: 'a2',
      title:
          'Anthropic raises \$8B Series F at \$200B valuation led by Google and a Gulf sovereign fund',
      summary:
          'The round nearly doubles Anthropic\'s valuation in 6 months. Funding will go to compute, safety research, and pushing Claude into enterprise sales.',
      imageUrl:
          'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=1200',
      url: 'https://techcrunch.com/anthropic-series-f',
      source: MockSources.techCrunch,
      author: 'Connie Loizos',
      publishedAt: _hoursAgo(5),
      topics: ['AI', 'Funding', 'Startups'],
      companies: ['Anthropic', 'Google'],
      stack: ['LLM'],
      trendScore: 92,
      viralityScore: 88,
      whyItMatters:
          'Anthropic now has the second-largest AI war chest after OpenAI. The Google participation deepens the Vertex AI partnership and signals Google still hedges its own Gemini bet. \$200B implies the market expects Claude to capture serious enterprise share.',
      keyPoints: [
        '\$8B raised at \$200B post-money',
        'Lead investors: Google, Mubadala (UAE)',
        'Existing investors Lightspeed, Spark, Bessemer all followed on',
        'Anthropic will spend ~\$5B of the round on compute over 18 months',
        'No IPO timeline disclosed',
      ],
      relatedRepos: [
        const GithubRepo(
          id: 'r3',
          fullName: 'anthropics/anthropic-sdk-python',
          description: 'Anthropic SDK for Python',
          url: 'https://github.com/anthropics/anthropic-sdk-python',
          language: 'Python',
          stars: 1820,
          forks: 287,
          starsThisWeek: 124,
        ),
      ],
      discussions: const [],
    ),
    Article(
      id: 'a3',
      title:
          'Linux kernel 6.13 lands with Rust async runtime in mainline — first non-C async code shipped',
      summary:
          'After 3 years of debate, the Rust async runtime is now in mainline Linux. The first production driver to use it is a new NVMe controller.',
      imageUrl:
          'https://images.unsplash.com/photo-1629654297299-c8506221ca97?w=1200',
      url: 'https://lwn.net/kernel-6-13-rust-async',
      source: MockSources.hackerNews,
      author: 'gregkh',
      publishedAt: _hoursAgo(8),
      topics: ['Open Source', 'Web Development'],
      companies: [],
      stack: ['Rust', 'Linux'],
      trendScore: 86,
      viralityScore: 79,
      whyItMatters:
          'Rust async in mainline ends the "is Rust really happening in kernel?" debate. Driver authors now have a real path to writing safer high-throughput code. Expect networking and storage drivers to follow within 12 months.',
      keyPoints: [
        'Rust async runtime merged after 47 review rounds',
        'First user: a new NVMe-oF driver from Samsung',
        'Linus signed off with rare public endorsement',
        'Kernel maintainers must still approve Rust per-subsystem',
        'C remains the default; Rust opt-in for new code',
      ],
      relatedRepos: [
        const GithubRepo(
          id: 'r4',
          fullName: 'Rust-for-Linux/linux',
          description: 'Adding support for the Rust language to the Linux kernel',
          url: 'https://github.com/Rust-for-Linux/linux',
          language: 'Rust',
          stars: 4120,
          forks: 198,
          starsThisWeek: 312,
        ),
      ],
      discussions: const [],
    ),
    Article(
      id: 'a4',
      title:
          'NVIDIA announces RTX 6090 with 64GB VRAM aimed at local LLM inference',
      summary:
          'The 6090 doubles VRAM over the 5090 and targets developers running 70B+ models locally. \$2,499 MSRP, shipping June 2026.',
      imageUrl:
          'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=1200',
      url: 'https://nvidia.com/rtx-6090',
      source: MockSources.theVerge,
      author: 'Tom Warren',
      publishedAt: _hoursAgo(12),
      topics: ['AI', 'NVIDIA'],
      companies: ['NVIDIA'],
      stack: ['CUDA', 'GPU'],
      trendScore: 89,
      viralityScore: 91,
      whyItMatters:
          'A 64GB consumer card collapses the gap between hobbyist and lab-grade local inference. 70B-class models become reasonable for single-machine deployment, which weakens the case for paying API rates on cheaper models.',
      keyPoints: [
        '64GB GDDR7 VRAM, 1.5TB/s memory bandwidth',
        '\$2,499 MSRP — same price as 5090 launched at',
        'Shipping June 2026',
        '70B-class models fit comfortably with quantization',
        'New tensor cores claim 2.4x INT4 perf vs 5090',
      ],
      relatedRepos: const [],
      discussions: const [],
    ),
    Article(
      id: 'a5',
      title:
          'YC W26 batch: 38% of companies are AI agents, 12% are dev tooling, 0% are crypto',
      summary:
          'YC\'s newest batch shows the strongest concentration in AI agents yet. Crypto has disappeared entirely from the batch composition.',
      imageUrl:
          'https://images.unsplash.com/photo-1551434678-e076c223a692?w=1200',
      url: 'https://ycombinator.com/blog/w26-batch',
      source: MockSources.techCrunch,
      author: 'Anna Heim',
      publishedAt: _hoursAgo(16),
      topics: ['Startups', 'AI'],
      companies: ['Y Combinator'],
      stack: [],
      trendScore: 81,
      viralityScore: 76,
      whyItMatters:
          'YC\'s batch composition is a leading indicator of which categories smart founders think they can win in. The AI-agent concentration signals consensus the AI infrastructure layer is set; the application layer is the prize.',
      keyPoints: [
        '38% AI agents — highest concentration in YC history',
        '12% dev tooling, 9% B2B SaaS, 8% vertical AI',
        'Zero crypto companies for the first time since 2014',
        '47% of founders are technical (down from 62%)',
        'Median founder age: 27',
      ],
      relatedRepos: const [],
      discussions: const [],
    ),
    Article(
      id: 'a6',
      title: 'GitHub Trending: bun adds native React Server Components support',
      summary:
          'Bun 1.5 ships RSC support that bypasses Webpack and Turbopack entirely. Early benchmarks show 4x faster RSC builds.',
      imageUrl:
          'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=1200',
      url: 'https://github.com/oven-sh/bun/releases/v1.5',
      source: MockSources.githubTrending,
      author: 'Jarred Sumner',
      publishedAt: _hoursAgo(20),
      topics: ['Open Source', 'Web Development'],
      companies: [],
      stack: ['JavaScript', 'TypeScript', 'React'],
      trendScore: 83,
      viralityScore: 71,
      whyItMatters:
          'Bun shipping RSC natively skips a layer that Next.js apps spent two years stabilizing. If the build times hold up in real apps, this becomes a real threat to the Vite + Next status quo.',
      keyPoints: [
        'Native React Server Components in Bun runtime',
        '4x faster RSC builds vs Turbopack in early benchmarks',
        'Drop-in for most Next.js App Router projects',
        'Still missing: edge runtime parity',
      ],
      relatedRepos: [
        const GithubRepo(
          id: 'r5',
          fullName: 'oven-sh/bun',
          description: 'Incredibly fast JavaScript runtime, bundler, transpiler and package manager',
          url: 'https://github.com/oven-sh/bun',
          language: 'Zig',
          stars: 82400,
          forks: 3120,
          starsThisWeek: 2840,
        ),
      ],
      discussions: const [],
    ),
    Article(
      id: 'a7',
      title:
          'Meta open-sources Llama 4 with a permissive license — 405B and 70B variants',
      summary:
          'Llama 4 lands with vision, voice, and a license that finally allows full commercial use without revenue caps.',
      imageUrl:
          'https://images.unsplash.com/photo-1605379399642-870262d3d051?w=1200',
      url: 'https://ai.meta.com/llama-4',
      source: MockSources.hackerNews,
      author: 'Yann LeCun',
      publishedAt: _hoursAgo(24),
      topics: ['AI', 'Open Source', 'Meta'],
      companies: ['Meta'],
      stack: ['LLM', 'PyTorch'],
      trendScore: 95,
      viralityScore: 96,
      whyItMatters:
          'A 405B-parameter open-weight model with a real commercial license is the most consequential open-source release of the year. This kills the "you must use proprietary models for production" argument for most non-frontier use cases.',
      keyPoints: [
        '405B and 70B variants, both open weight',
        'Native multimodal: text, vision, voice',
        'Commercial license — no revenue cap',
        'Context: 256k tokens, with research version at 2M',
        'Beats GPT-5 on 4 of 12 standard benchmarks',
      ],
      relatedRepos: [
        const GithubRepo(
          id: 'r6',
          fullName: 'meta-llama/llama4',
          description: 'Reference implementation for Llama 4',
          url: 'https://github.com/meta-llama/llama4',
          language: 'Python',
          stars: 14200,
          forks: 1840,
          starsThisWeek: 8920,
        ),
      ],
      discussions: const [],
    ),
    Article(
      id: 'a8',
      title:
          'Apple to ship on-device Gemini-class model in iOS 19 — Siri rewrite ships with it',
      summary:
          'Apple Intelligence gets a real upgrade: a 30B on-device model from a partnership with Google, plus a full Siri rewrite using it.',
      imageUrl:
          'https://images.unsplash.com/photo-1605236453806-6ff36851218e?w=1200',
      url: 'https://9to5mac.com/ios-19-siri-rewrite',
      source: MockSources.arsTechnica,
      author: 'Mark Gurman',
      publishedAt: _hoursAgo(30),
      topics: ['AI', 'Apple'],
      companies: ['Apple', 'Google'],
      stack: ['iOS', 'CoreML'],
      trendScore: 91,
      viralityScore: 93,
      whyItMatters:
          'Apple admitting they need Google\'s model to ship a credible on-device assistant is a major shift. It pressures OpenAI (Apple\'s previous partner) and validates Gemini Nano as the on-device standard.',
      keyPoints: [
        '30B on-device model based on Gemini Nano architecture',
        'Full Siri rewrite — new voice, new memory, new tool use',
        'Ships with iOS 19 in September 2026',
        'Requires iPhone 17 Pro or newer due to memory needs',
        'Apple\'s OpenAI partnership reportedly being wound down',
      ],
      relatedRepos: const [],
      discussions: const [],
    ),
  ];
}
