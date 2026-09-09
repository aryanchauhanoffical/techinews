import 'package:flutter/material.dart';

/// Fade + rise entrance animation. Use with an increasing [delay] to stagger a
/// column of items. Respects the platform "reduce motion" setting (renders the
/// child immediately, no movement).
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = 22,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Expressive "ease out" curve for a calm, premium settle.
  static const Cubic _curve = Cubic(0.16, 1, 0.3, 1);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _c, curve: _curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: _curve));

    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Stagger helper: wraps each child in a [Reveal] with an incrementing delay.
List<Widget> stagger(
  List<Widget> children, {
  Duration base = const Duration(milliseconds: 60),
  Duration step = const Duration(milliseconds: 70),
}) {
  return [
    for (var i = 0; i < children.length; i++)
      Reveal(delay: base + step * i, child: children[i]),
  ];
}
