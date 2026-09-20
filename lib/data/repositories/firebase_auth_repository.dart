import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import 'auth_repository.dart';

/// Real auth backed by Firebase Auth, synced to the FastAPI backend.
///
/// Flow: provider sign-in (Google) → Firebase credential → POST the Firebase
/// ID token to `/auth/verify` (creates/fetches the Mongo user) → register the
/// device's FCM token. The backend profile (interests, premium, etc.) is the
/// source of truth returned to the app.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._dio);

  final Dio _dio;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  StreamSubscription<String>? _tokenSub;

  @override
  Future<AppUser?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final user = await _syncWithBackend() ?? _fromFirebase(u);
    // Re-register on every launch while signed in, not only at sign-in: the
    // server prunes tokens FCM reports dead, and Android rotates tokens, so a
    // returning user would otherwise silently stop receiving pushes.
    unawaited(_registerFcmToken());
    return user;
  }

  @override
  Future<AppUser> signIn(AuthProvider provider, {String? email}) async {
    switch (provider) {
      case AuthProvider.google:
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          throw Exception('Sign-in cancelled');
        }
        final googleAuth = await googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        await _auth.signInWithCredential(credential);
        break;
      case AuthProvider.email:
        // Email OTP not wired yet — use an anonymous session so the rest of
        // the app is reachable. Replace with email-link/OTP later.
        await _auth.signInAnonymously();
        break;
      case AuthProvider.apple:
      case AuthProvider.github:
        throw Exception('${provider.name} sign-in is coming soon');
    }

    final user = await _syncWithBackend() ?? _fromFirebase(_auth.currentUser!);
    await _registerFcmToken();
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {/* not signed in via Google */}
    await _auth.signOut();
  }

  @override
  Future<AppUser> updateProfile({
    List<String>? interests,
    NotificationMode? notificationMode,
  }) async {
    final body = <String, dynamic>{};
    if (interests != null) body['interests'] = interests;
    if (notificationMode != null) {
      body['notification_mode'] = _modeToApi(notificationMode);
    }
    final res = await _dio.patch('/api/v1/auth/me', data: body);
    return _fromJson(res.data as Map<String, dynamic>);
  }

  // ---- helpers ------------------------------------------------------------

  Future<AppUser?> _syncWithBackend() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) return null;
    try {
      final res = await _dio.post(
        '/api/v1/auth/verify',
        data: {'id_token': token},
      );
      return _fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null; // backend unreachable — fall back to the Firebase profile
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _dio.post('/api/v1/auth/fcm-token', data: {'token': token});
      }
      // Keep the server in step when FCM rotates the token mid-session.
      _tokenSub ??= messaging.onTokenRefresh.listen((t) {
        if (_auth.currentUser != null) {
          _dio.post('/api/v1/auth/fcm-token', data: {'token': t}).ignore();
        }
      });
    } catch (_) {
      // non-fatal — push just won't work until next successful registration
    }
  }

  AppUser _fromFirebase(fb.User u) => AppUser(
        id: u.uid,
        email: u.email ?? 'unknown@techinews.app',
        // An anonymous session is a guest who happens to have a token, not a
        // signed-in account; say so rather than inventing a name.
        displayName: u.displayName ?? (u.isAnonymous ? 'Guest reader' : 'TechiNews User'),
        photoUrl: u.photoURL,
        createdAt: u.metadata.creationTime ?? DateTime.now(),
      );

  AppUser _fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String? ?? 'unknown@techinews.app',
        displayName: j['display_name'] as String? ?? 'TechiNews User',
        photoUrl: j['photo_url'] as String?,
        interests: (j['interests'] as List?)?.cast<String>() ?? const [],
        notificationMode: _modeFromApi(j['notification_mode'] as String?),
        isPremium: j['is_premium'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

String _modeToApi(NotificationMode m) => switch (m) {
      NotificationMode.instant => 'instant',
      NotificationMode.dailyDigest => 'daily_digest',
      NotificationMode.weeklyDigest => 'weekly_digest',
      NotificationMode.silent => 'silent',
    };

NotificationMode _modeFromApi(String? s) => switch (s) {
      'instant' => NotificationMode.instant,
      'weekly_digest' => NotificationMode.weeklyDigest,
      'silent' => NotificationMode.silent,
      _ => NotificationMode.dailyDigest,
    };
