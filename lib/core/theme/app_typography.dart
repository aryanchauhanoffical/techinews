import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Three voices:
///  - Shantell Sans, heavy: headlines, wordmark, section titles, buttons.
///    A display face with a hand-cut edge, still a proper text font.
///  - DM Sans: body copy, controls, metadata. Clean and highly legible.
///  - Kalam: handwriting, reserved for annotations, stickers and doodle
///    captions. Never for paragraphs.
/// `serif` and `mono` keep their names so call sites read as "headline
/// voice" and "metadata voice" without a rename sweep.
class AppTypography {
  AppTypography._();

  /// Headline voice.
  static TextStyle serif(double size,
          {FontWeight weight = FontWeight.w800,
          double height = 1.15,
          double spacing = -0.2,
          Color color = AppColors.ink}) =>
      GoogleFonts.shantellSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color,
      );

  static TextStyle sans(double size,
          {FontWeight weight = FontWeight.w400,
          double height = 1.5,
          double spacing = 0,
          Color color = AppColors.ink}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color,
      );

  /// Metadata voice: sources, timestamps, counts.
  static TextStyle mono(double size,
          {FontWeight weight = FontWeight.w500,
          double spacing = 0,
          Color color = AppColors.inkSecondary}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: 1.3,
        color: color,
      );

  /// Handwriting. Annotations, stickers, doodle captions only.
  static TextStyle hand(double size,
          {FontWeight weight = FontWeight.w700,
          double height = 1.15,
          Color color = AppColors.yellow}) =>
      GoogleFonts.kalam(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );

  /// Small metadata line: Hacker News · 2d
  static TextStyle kicker({Color color = AppColors.inkMuted}) =>
      mono(12.5, color: color);

  static TextTheme build() {
    return TextTheme(
      displayLarge: serif(42, height: 1.05, spacing: -0.8),
      displayMedium: serif(34, height: 1.08, spacing: -0.6),
      displaySmall: serif(27, height: 1.15, spacing: -0.4),
      headlineLarge: serif(25, height: 1.2, spacing: -0.3),
      headlineMedium: serif(21, height: 1.25),
      headlineSmall: serif(17.5, weight: FontWeight.w700, height: 1.3),
      titleLarge: serif(18, weight: FontWeight.w700, height: 1.3),
      titleMedium: sans(15.5, weight: FontWeight.w600, height: 1.35),
      titleSmall: sans(13.5, weight: FontWeight.w600, height: 1.35, color: AppColors.inkSecondary),
      bodyLarge: sans(16.5, height: 1.6, color: AppColors.inkSecondary),
      bodyMedium: sans(14.5, height: 1.55, color: AppColors.inkSecondary),
      bodySmall: sans(12.5, height: 1.45, color: AppColors.inkMuted),
      labelLarge: serif(15, weight: FontWeight.w700, height: 1.2),
      labelMedium: sans(12.5, weight: FontWeight.w600, height: 1.2, color: AppColors.inkSecondary),
      labelSmall: mono(11.5, color: AppColors.inkMuted),
    );
  }
}
