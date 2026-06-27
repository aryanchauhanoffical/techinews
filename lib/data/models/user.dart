import 'package:equatable/equatable.dart';

enum NotificationMode { instant, dailyDigest, weeklyDigest, silent }

class AppUser extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> interests;
  final NotificationMode notificationMode;
  final bool isPremium;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.interests = const [],
    this.notificationMode = NotificationMode.dailyDigest,
    this.isPremium = false,
    required this.createdAt,
  });

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    List<String>? interests,
    NotificationMode? notificationMode,
    bool? isPremium,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      interests: interests ?? this.interests,
      notificationMode: notificationMode ?? this.notificationMode,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, displayName, interests, notificationMode, isPremium];
}
