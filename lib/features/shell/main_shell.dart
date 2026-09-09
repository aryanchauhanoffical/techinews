import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Four tabs. Active tab is blue with a short marker scribble beneath it.
/// On wide screens the page content is capped at a readable column so the
/// mobile layout is never simply stretched.
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (AppRoutes.feed, 'Home', AppIcons.home, AppIcons.homeActive),
    (AppRoutes.discover, 'Discover', AppIcons.discover, AppIcons.discoverActive),
    (AppRoutes.saved, 'Saved', AppIcons.bookmark, AppIcons.bookmarkFilled),
    (AppRoutes.profile, 'Account', AppIcons.account, AppIcons.accountActive),
  ];

  static const double maxContentWidth = 760;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1)).clamp(0, _tabs.length - 1);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: child,
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _Tab(
                          label: _tabs[i].$2,
                          icon: i == index ? _tabs[i].$4 : _tabs[i].$3,
                          active: i == index,
                          onTap: () => context.go(_tabs[i].$1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.inkMuted;
    final reduced = MediaQuery.of(context).disableAnimations;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: AppTypography.sans(11.5, weight: FontWeight.w600, height: 1, color: color)),
            const SizedBox(height: 3),
            AnimatedOpacity(
              duration: Duration(milliseconds: reduced ? 0 : 200),
              opacity: active ? 1 : 0,
              child: SizedBox(
                width: 26,
                height: 6,
                child: CustomPaint(painter: _ScribbleMark(AppColors.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScribbleMark extends CustomPainter {
  final Color color;
  _ScribbleMark(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(1, s.height * 0.4)
      ..quadraticBezierTo(s.width * 0.4, s.height * 0.1, s.width * 0.6, s.height * 0.5)
      ..quadraticBezierTo(s.width * 0.8, s.height * 0.9, s.width - 1, s.height * 0.4);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScribbleMark o) => o.color != color;
}
