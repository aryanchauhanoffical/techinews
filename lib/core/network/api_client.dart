import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves the backend API base URL across emulator, simulator, and device.
///
/// Priority:
///   1. `API_BASE_URL` from .env if set
///   2. Android emulator default: http://10.0.2.2:8000 (host loopback)
///   3. iOS simulator / desktop / web default: http://127.0.0.1:8000
String resolveBaseUrl({String fallback = 'http://127.0.0.1:8000'}) {
  final fromEnv = dotenv.maybeGet('API_BASE_URL');
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  return fallback;
}

Dio buildDio({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'accept': 'application/json'},
    ),
  );
  // Attach the current Firebase ID token (if signed in) to every request, so
  // protected backend routes authenticate. Safe no-op when Firebase isn't
  // initialized or no user is signed in.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (_) {
          // Firebase not available — proceed unauthenticated
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}
