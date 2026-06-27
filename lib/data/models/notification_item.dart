import 'package:equatable/equatable.dart';

enum NotificationKind { breaking, digest, githubTrend, funding, hiring, system }

class NotificationItem extends Equatable {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? articleId;
  final String? imageUrl;
  final DateTime receivedAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.articleId,
    this.imageUrl,
    required this.receivedAt,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      kind: kind,
      title: title,
      body: body,
      articleId: articleId,
      imageUrl: imageUrl,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, isRead];
}
