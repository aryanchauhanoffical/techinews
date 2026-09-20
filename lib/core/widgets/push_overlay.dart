import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'doodles.dart';

/// Shows pushes that arrive while the app is open, and opens the story when a
/// push is tapped.
///
/// Android only draws a notification itself when the app is in the background.
/// With the app open FCM hands the message straight to the code and nothing is
/// drawn, so a push looks like it never arrived. This paints an in-app banner
/// instead, in the app's own design rather than the system's, and wires the
/// three ways a tap can reach us:
///
///   * `onMessage` — app open, we draw the banner
///   * `onMessageOpenedApp` — tapped while the app was backgrounded
///   * `getInitialMessage` — tapped while the app was not running
class PushOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const PushOverlay({super.key, required this.child});

  @override
  ConsumerState<PushOverlay> createState() => _PushOverlayState();
}

class _PushOverlayState extends ConsumerState<PushOverlay> {
  RemoteMessage? _banner;
  Timer? _hide;
  final List<StreamSubscription<RemoteMessage>> _subs = [];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    try {
      _subs.add(FirebaseMessaging.onMessage.listen(_show));
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      FirebaseMessaging.instance.getInitialMessage().then((m) {
        if (m != null) _open(m);
      });
    } catch (e) {
      debugPrint('push overlay unavailable: $e');
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _show(RemoteMessage m) {
    if (m.notification == null) return;
    setState(() => _banner = m);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _open(RemoteMessage m) {
    final id = m.data['article_id'];
    if (id == null || id.isEmpty) return;
    // The router may not be mounted on the very first frame after a cold
    // start from a notification tap, so wait one frame before navigating.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(routerProvider).push(AppRoutes.articlePath(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _banner;
    return Stack(
      children: [
        widget.child,
        if (m != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            child: _Banner(
              message: m,
              onTap: () {
                setState(() => _banner = null);
                _open(m);
              },
              onDismiss: () => setState(() => _banner = null),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final RemoteMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _Banner({required this.message, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final n = message.notification!;
    final hue = AppColors.hue(message.data['kind'] ?? 'breaking');
    return Dismissible(
      key: ValueKey(message.messageId ?? n.title),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: PopCard(
          hue: hue,
          glow: true,
          fill: AppColors.surfaceRaised,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.bell, size: 20, color: hue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.title != null)
                      Text(n.title!,
                          style: AppTypography.serif(15, weight: FontWeight.w800, height: 1.15, color: AppColors.ink),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (n.body != null) ...[
                      const SizedBox(height: 3),
                      Text(n.body!,
                          style: AppTypography.sans(13, color: AppColors.inkSecondary, height: 1.3),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
