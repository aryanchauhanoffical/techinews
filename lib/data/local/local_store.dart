import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/user.dart';

/// Thin wrapper over SharedPreferences for everything that must survive a
/// restart without a backend account: saved and read article ids, guest
/// interests, notification mode, onboarding flag, and a small article cache
/// so Saved works offline.
class LocalStore {
  LocalStore(this._p);
  final SharedPreferences _p;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  static const _kSaved = 'saved_ids';
  static const _kRead = 'read_ids';

  Set<String> get savedIds => (_p.getStringList(_kSaved) ?? const []).toSet();
  Set<String> get readIds => (_p.getStringList(_kRead) ?? const []).toSet();

  Future<void> setSaved(Set<String> ids) => _p.setStringList(_kSaved, ids.toList());
  Future<void> setRead(Set<String> ids) => _p.setStringList(_kRead, ids.take(500).toList());

  static const _kReadNotif = 'read_notification_ids';
  Set<String> get readNotificationIds => (_p.getStringList(_kReadNotif) ?? const []).toSet();
  Future<void> setReadNotifications(Set<String> ids) => _p.setStringList(_kReadNotif, ids.take(300).toList());

  static const _kTopicAlerts = 'topic_alerts';
  List<String> get topicAlerts => _p.getStringList(_kTopicAlerts) ?? const [];
  Future<void> setTopicAlerts(List<String> v) => _p.setStringList(_kTopicAlerts, v.take(20).toList());

  List<String> get interests => _p.getStringList(AppConstants.prefsKeyUserInterests) ?? const [];
  Future<void> setInterests(List<String> v) => _p.setStringList(AppConstants.prefsKeyUserInterests, v);

  NotificationMode get notificationMode {
    final raw = _p.getString(AppConstants.prefsKeyNotificationMode);
    return NotificationMode.values.firstWhere((m) => m.name == raw, orElse: () => NotificationMode.dailyDigest);
  }

  Future<void> setNotificationMode(NotificationMode m) => _p.setString(AppConstants.prefsKeyNotificationMode, m.name);

  bool get onboardingComplete => _p.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete(bool v) => _p.setBool(AppConstants.prefsKeyOnboardingComplete, v);

  Map<String, dynamic>? cachedArticle(String id) {
    final raw = _p.getString('article_$id');
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> cacheArticle(String id, Map<String, dynamic> json) => _p.setString('article_$id', jsonEncode(json));
  Future<void> dropArticle(String id) => _p.remove('article_$id');
}
