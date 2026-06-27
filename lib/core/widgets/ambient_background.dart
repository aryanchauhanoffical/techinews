import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;
  final double intensity;

  const AmbientBackground({
    super.key,
    required this.child,
    this.intensity = 0.08,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return widget.child;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.ambientGradient),
          ),
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(
                  top: -80 + (_ctrl.value * 40),
                  left: -60,
                  child: _Blob(
                    color: AppColors.brandPrimary.withValues(alpha: widget.intensity),
                    size: 260,
                  ),
                ),
                Positioned(
                  top: 200 - (_ctrl.value * 30),
                  right: -100 + (_ctrl.value * 20),
                  child: _Blob(
                    color: AppColors.brandAccent.withValues(alpha: widget.intensity * 0.8),
                    size: 220,
                  ),
                ),
              ],
            );
          },
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}
