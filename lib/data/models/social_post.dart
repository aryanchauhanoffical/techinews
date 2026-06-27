import 'package:equatable/equatable.dart';

enum SocialPlatform { reddit, twitter, hackerNews }

class SocialPost extends Equatable {
  final String id;
  final SocialPlatform platform;
  final String author;
  final String? authorHandle;
  final String content;
  final String url;
  final int upvotes;
  final int comments;
  final DateTime postedAt;
  final String sentiment;

  const SocialPost({
    required this.id,
    required this.platform,
    required this.author,
    this.authorHandle,
    required this.content,
    required this.url,
    this.upvotes = 0,
    this.comments = 0,
    required this.postedAt,
    this.sentiment = 'neutral',
  });

  @override
  List<Object?> get props => [id, platform];
}
