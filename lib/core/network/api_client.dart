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
      // The API runs on Render's free tier, which sleeps when idle and takes
      // 30-45 s to wake (measured 32.5 s on 2026-09-20). Timeouts must outlast
      // a cold start or the first open after a quiet spell fails outright.
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 75),
      sendTimeout: const Duration(seconds: 25),
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
      // One automatic retry for GETs that time out or can't connect: a request
      // that dies while the server is waking usually succeeds immediately after.
      onError: (e, handler) async {
        final o = e.requestOptions;
        final transient = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        if (transient && o.method == 'GET' && o.extra['retried'] != true) {
          o.extra['retried'] = true;
          try {
            return handler.resolve(await dio.fetch(o));
          } catch (_) {
            // fall through with the original error
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}
