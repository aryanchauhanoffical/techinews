import '../mock/mock_notifications.dart';
import '../models/notification_item.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> list();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class MockNotificationsRepository implements NotificationsRepository {
  late final List<NotificationItem> _items =
      List<NotificationItem>.from(MockNotifications.all);

  @override
  Future<List<NotificationItem>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1) _items[i] = _items[i].copyWith(isRead: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }
}
