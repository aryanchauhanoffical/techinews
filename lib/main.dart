import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/demo_mode.dart';
import 'data/local/local_store.dart';
import 'data/models/user.dart';
import 'services/demo_session.dart';
import 'services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env — if missing or malformed, we fall through to in-code defaults.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // ignore — assume mock mode
  }
  // Initialize Firebase (Android reads google-services.json natively). On
  // platforms without config (desktop/web), this throws — we continue without
  // auth, and providers fall back to the mock auth repository.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // ignore — Firebase not configured for this platform
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final store = await LocalStore.open();
  if (kDemoMode) {
    // Replay the first run every launch: splash, welcome, pick three topics.
    // Saved stories are left alone so a demo can build up a shelf.
    await store.setOnboardingComplete(false);
    await store.setInterests(const []);
    await store.setNotificationMode(NotificationMode.instant);
    // Anonymous session + push registration, in the background so it never
    // delays the first frame.
    unawaited(DemoSession.start());
  }
  runApp(ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: const TechiNewsApp(),
  ));
}
