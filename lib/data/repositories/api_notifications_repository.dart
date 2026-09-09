import 'package:dio/dio.dart';

import '../local/local_store.dart';
import '../models/notification_item.dart';
import 'notifications_repository.dart';

/// Inbox items come from the backend, derived from real stories. Read state
/// is per device, so it lives in LocalStore.
class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._dio, this._store);
  final Dio _dio;
  final LocalStore _store;
  List<String> _lastIds = const [];

  @override
  Future<List<NotificationItem>> list() async {
    final r = await _dio.get('/api/v1/notifications');
    final read = _store.readNotificationIds;
    final items = (r.data as List).cast<Map<String, dynamic>>().map((j) {
      final kind = NotificationKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => NotificationKind.system);
      return NotificationItem(
        id: j['id'] as String,
        kind: kind,
        title: j['title'] as String,
        body: (j['body'] ?? '') as String,
        articleId: j['article_id'] as String?,
        imageUrl: j['image_url'] as String?,
        receivedAt: DateTime.tryParse('${j['received_at']}Z')?.toLocal() ?? DateTime.now(),
        isRead: read.contains(j['id']),
      );
    }).toList();
    _lastIds = items.map((n) => n.id).toList();
    return items;
  }

  @override
  Future<void> markRead(String id) => _store.setReadNotifications(_store.readNotificationIds..add(id));

  @override
  Future<void> markAllRead() => _store.setReadNotifications(_store.readNotificationIds..addAll(_lastIds));
}
