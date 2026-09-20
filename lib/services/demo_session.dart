import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';

/// Background bootstrap for a demo build.
///
/// A push needs two things the demo has no screen for: an account the server
/// can attach the token to, and the Android notification permission. An
/// anonymous Firebase session supplies the first without asking anyone to sign
/// in, and it carries a real ID token, so `/auth/fcm-token` accepts it.
///
/// Everything here is best-effort: the app is fully usable if it fails.
class DemoSession {
  static Future<void> start() async {
    if (kIsWeb) return;
    try {
      final auth = fb.FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final messaging = FirebaseMessaging.instance;
      // Android 13+ shows the system prompt here; earlier versions return
      // granted straight away.
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('demo: notification permission denied, push will not show');
      }
      final token = await messaging.getToken();
      if (token == null) return;
      await buildDio().post('/api/v1/auth/fcm-token', data: {'token': token});
      debugPrint('demo: registered for push');
    } catch (e) {
      debugPrint('demo bootstrap failed: $e');
    }
  }
}
