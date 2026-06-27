import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

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
  runApp(const ProviderScope(child: TechiNewsApp()));
}
