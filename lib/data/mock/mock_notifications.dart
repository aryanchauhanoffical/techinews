import '../models/notification_item.dart';

class MockNotifications {
  MockNotifications._();

  static DateTime _minsAgo(int m) =>
      DateTime.now().subtract(Duration(minutes: m));

  static final List<NotificationItem> all = [
    NotificationItem(
      id: 'n1',
      kind: NotificationKind.breaking,
      title: 'OpenAI just launched GPT-5.5',
      body:
          '10M-token context, native agentic tools, and 40% cheaper than GPT-5.',
      articleId: 'a1',
      receivedAt: _minsAgo(8),
    ),
    NotificationItem(
      id: 'n2',
      kind: NotificationKind.funding,
      title: 'Anthropic raises \$8B at \$200B valuation',
      body: 'Led by Google and Mubadala. Compute-heavy round.',
      articleId: 'a2',
      receivedAt: _minsAgo(120),
    ),
    NotificationItem(
      id: 'n3',
      kind: NotificationKind.githubTrend,
      title: 'meta-llama/llama4 is exploding',
      body: '+8.9K stars this week — Llama 4 reference repo.',
      articleId: 'a7',
      receivedAt: _minsAgo(240),
      isRead: true,
    ),
    NotificationItem(
      id: 'n4',
      kind: NotificationKind.digest,
      title: 'Your daily digest is ready',
      body: '5 stories curated for AI, Open Source, Startups.',
      receivedAt: _minsAgo(720),
      isRead: true,
    ),
  ];
}
