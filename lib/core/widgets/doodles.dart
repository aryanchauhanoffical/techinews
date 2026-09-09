import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Hand-drawn decoration kit. Everything here is painted, so it is crisp at
/// any size, recolourable, and costs nothing to load. Use sparingly: one or
/// two marks per screen section, never on controls.

/// Four-point spark. `turn` rotates it so a cluster never looks stamped.
class Spark extends StatelessWidget {
  final double size;
  final Color color;
  final double turn;
  const Spark({super.key, this.size = 14, this.color = AppColors.yellow, this.turn = 0});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: turn,
      child: CustomPaint(size: Size.square(size), painter: _SparkPainter(color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  _SparkPainter(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    final k = r * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k * 0.6, c.dy - k * 0.6, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k * 0.6, c.dy + k * 0.6, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k * 0.6, c.dy + k * 0.6, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k * 0.6, c.dy - k * 0.6, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.color != color;
}

/// Three short speed lines, like the marks beside a wordmark.
class SpeedLines extends StatelessWidget {
  final Color color;
  final double size;
  const SpeedLines({super.key, this.color = AppColors.yellow, this.size = 18});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _SpeedPainter(color));
}

class _SpeedPainter extends CustomPainter {
  final Color color;
  _SpeedPainter(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s.width * 0.15, s.height * 0.55), Offset(s.width * 0.45, s.height * 0.15), p);
    canvas.drawLine(Offset(s.width * 0.55, s.height * 0.6), Offset(s.width * 0.9, s.height * 0.35), p);
    canvas.drawLine(Offset(s.width * 0.4, s.height * 0.95), Offset(s.width * 0.6, s.height * 0.7), p);
  }

  @override
  bool shouldRepaint(_SpeedPainter o) => o.color != color;
}

/// Marker underline with a slight wobble. Wrap a headline word with it.
class Scribble extends StatelessWidget {
  final Widget child;
  final Color color;
  final double thickness;
  final double inset;
  const Scribble({super.key, required this.child, this.color = AppColors.yellow, this.thickness = 4, this.inset = -2});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: inset,
          height: thickness * 2.2,
          child: CustomPaint(painter: _ScribblePainter(color, thickness)),
        ),
      ],
    );
  }
}

class _ScribblePainter extends CustomPainter {
  final Color color;
  final double thickness;
  _ScribblePainter(this.color, this.thickness);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final y = s.height * 0.55;
    final path = Path()
      ..moveTo(2, y)
      ..quadraticBezierTo(s.width * 0.3, y - thickness * 0.9, s.width * 0.55, y + thickness * 0.2)
      ..quadraticBezierTo(s.width * 0.8, y + thickness * 0.9, s.width - 2, y - thickness * 0.3);
    canvas.drawPath(path, p);
    final p2 = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = thickness * 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(s.width * 0.2, y + thickness * 1.1), Offset(s.width * 0.7, y + thickness * 1.35), p2);
  }

  @override
  bool shouldRepaint(_ScribblePainter o) => o.color != color || o.thickness != thickness;
}

/// Hand-drawn arrow pointing right, used beside "See all" and on CTAs.
class DoodleArrow extends StatelessWidget {
  final Color color;
  final double width;
  const DoodleArrow({super.key, this.color = AppColors.ink, this.width = 22});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, width * 0.55), painter: _ArrowPainter(color));
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final y = s.height / 2;
    final path = Path()
      ..moveTo(1, y + 0.5)
      ..quadraticBezierTo(s.width * 0.5, y - 1.5, s.width - 2, y)
      ..moveTo(s.width * 0.62, 1)
      ..lineTo(s.width - 2, y)
      ..lineTo(s.width * 0.62, s.height - 1);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ArrowPainter o) => o.color != color;
}

/// Sticker label: filled hue, dark text, a tiny tilt. "Trending #1".
class Sticker extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;
  final double tilt;
  final IconData? icon;
  final bool hand;
  const Sticker(this.text, {super.key, this.color = AppColors.yellow, this.textColor, this.tilt = -0.04, this.icon, this.hand = false});

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? (color == AppColors.yellow || color == AppColors.green ? AppColors.onYellow : AppColors.onAccent);
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.canvas, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
            Text(
              text,
              style: hand ? AppTypography.hand(13, color: fg) : AppTypography.serif(12.5, weight: FontWeight.w800, height: 1.1, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotated yellow note with handwriting. One per screen at most.
class StickyNote extends StatelessWidget {
  final String text;
  final double tilt;
  final Color color;
  const StickyNote(this.text, {super.key, this.tilt = 0.14, this.color = AppColors.yellow});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(2, 4))],
        ),
        child: Text(text, textAlign: TextAlign.center, style: AppTypography.hand(14, color: AppColors.onYellow)),
      ),
    );
  }
}

/// Outlined poster card. Thin hue border, faint hue glow, dark fill.
class PopCard extends StatelessWidget {
  final Widget child;
  final Color hue;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final double borderWidth;
  final Color? fill;
  const PopCard({
    super.key,
    required this.child,
    this.hue = AppColors.hairlineStrong,
    this.radius = AppSpacing.radiusLg,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.glow = false,
    this.borderWidth = 1.4,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      side: BorderSide(color: hue, width: borderWidth),
      borderRadius: BorderRadius.circular(radius),
    );
    return Container(
      decoration: glow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [BoxShadow(color: hue.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: -2)],
            )
          : null,
      child: Material(
        color: fill ?? AppColors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Pill tag with a hue outline: #OpenSource. Tags are labels, not buttons,
/// so the pill shape is fine here.
class HueTag extends StatelessWidget {
  final String label;
  final Color? hue;
  final bool filled;
  final VoidCallback? onTap;
  final bool dense;
  const HueTag(this.label, {super.key, this.hue, this.filled = false, this.onTap, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final h = hue ?? AppColors.hue(label);
    final fg = filled ? (h == AppColors.yellow || h == AppColors.green ? AppColors.onYellow : AppColors.onAccent) : h;
    return Material(
      color: filled ? h : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: h, width: 1.3)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 13, vertical: dense ? 4 : 7),
          child: Text(
            label,
            style: AppTypography.sans(dense ? 12 : 13.5, weight: FontWeight.w600, height: 1.2, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Bookmark that pops when toggled on. Honors reduced motion.
class PopBookmark extends StatefulWidget {
  final bool saved;
  final Future<void> Function() onTap;
  final double size;
  const PopBookmark({super.key, required this.saved, required this.onTap, this.size = 20});
  @override
  State<PopBookmark> createState() => _PopBookmarkState();
}

class _PopBookmarkState extends State<PopBookmark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didUpdateWidget(PopBookmark old) {
    super.didUpdateWidget(old);
    if (!old.saved && widget.saved && !MediaQuery.of(context).disableAnimations) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = _c.value;
            final scale = 1 + math.sin(t * math.pi) * 0.35;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (t > 0 && t < 1)
                  for (var i = 0; i < 6; i++)
                    Transform.translate(
                      offset: Offset.fromDirection(i * math.pi / 3, 6 + t * 12),
                      child: Opacity(
                        opacity: (1 - t).clamp(0, 1),
                        child: Spark(size: 5, color: i.isEven ? AppColors.yellow : AppColors.pink),
                      ),
                    ),
                Transform.scale(
                  scale: scale,
                  child: Icon(
                    widget.saved ? AppIcons.bookmarkFilled : AppIcons.bookmark,
                    size: widget.size,
                    color: widget.saved ? AppColors.accent : AppColors.inkMuted,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Wordmark: "Techi" white, "News" blue, with speed lines. Used on the
/// splash and the feed masthead.
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Techi',
            style: AppTypography.serif(size, weight: FontWeight.w800, height: 1, spacing: -0.8),
            children: [TextSpan(text: 'News', style: TextStyle(color: AppColors.accent))],
          ),
        ),
        const SizedBox(width: 4),
        Padding(padding: EdgeInsets.only(top: size * 0.05), child: SpeedLines(size: size * 0.6)),
      ],
    );
  }
}
