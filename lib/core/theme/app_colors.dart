import 'package:flutter/material.dart';

/// Pop palette. Near-black navy canvas, one electric blue for actions, and a
/// small set of poster hues (yellow, pink, green, purple, orange) used for
/// outlines, badges and topic tiles so the app reads like a hand-drawn
/// poster rather than a dashboard. Text stays white on dark for contrast.
class AppColors {
  AppColors._();

  static const Color canvas = Color(0xFF080D1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceRaised = Color(0xFF171F32);
  static const Color surfaceSunken = Color(0xFF050912);
  static const Color hairline = Color(0xFF1F2940);
  static const Color hairlineStrong = Color(0xFF33405C);

  static const Color ink = Color(0xFFF8FAFC);
  static const Color inkSecondary = Color(0xFF9AA6BA);
  static const Color inkMuted = Color(0xFF6F7B92);
  static const Color inkFaint = Color(0xFF3F4A62);

  static const Color accent = Color(0xFF2495FF);
  static const Color accentDeep = Color(0xFF1A73CC);
  static const Color onAccent = Color(0xFFFFFFFF);
  static Color accentWash = accent.withValues(alpha: 0.16);

  // Poster hues.
  static const Color yellow = Color(0xFFFFD43B);
  static const Color pink = Color(0xFFFF4F87);
  static const Color green = Color(0xFF38E59B);
  static const Color purple = Color(0xFF9B6CFF);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color cyan = Color(0xFF36CFEB);

  /// Warm mark for trending flames and hot scores.
  static const Color ember = orange;
  static const Color onYellow = Color(0xFF1A1400);

  static const Color success = green;
  static const Color warning = yellow;
  static const Color danger = pink;
  static const Color info = accent;

  static const List<Color> hues = [accent, pink, green, purple, yellow, orange, cyan];

  /// Stable hue for a label so the same topic is always the same colour.
  static Color hue(String key) => hues[key.toLowerCase().codeUnits.fold(0, (a, b) => a + b) % hues.length];

  /// Language colours for repo cards, matching GitHub's own so developers
  /// recognise them at a glance. Anything unknown falls back to muted ink.
  static Color language(String? lang) {
    switch ((lang ?? '').toLowerCase()) {
      case 'python':
        return const Color(0xFF3572A5);
      case 'typescript':
        return const Color(0xFF3178C6);
      case 'javascript':
        return const Color(0xFFF1E05A);
      case 'rust':
        return const Color(0xFFDEA584);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'swift':
        return const Color(0xFFF05138);
      case 'kotlin':
        return const Color(0xFFA97BFF);
      case 'c++':
      case 'cpp':
        return const Color(0xFFF34B7D);
      case 'c':
        return const Color(0xFF555555);
      case 'zig':
        return const Color(0xFFEC915C);
      default:
        return inkMuted;
    }
  }
}
