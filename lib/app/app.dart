import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/push_overlay.dart';
import '../services/providers.dart';
import 'router.dart';

class TechiNewsApp extends ConsumerWidget {
  const TechiNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // Pushes that land while the app is open get an in-app banner; Android
      // draws nothing itself in the foreground.
      builder: (context, child) => PushOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
