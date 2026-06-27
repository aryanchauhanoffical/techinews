import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color brandPrimary = Color(0xFF6366F1);
  static const Color brandPrimaryDark = Color(0xFF4F46E5);
  static const Color brandAccent = Color(0xFF06B6D4);
  static const Color brandHighlight = Color(0xFFFBBF24);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFF71717A);

  // Cinema-mobile palette: avoids pure black (OLED smear), uses graded depth.
  static const Color darkBg = Color(0xFF050506);
  static const Color darkBgDeep = Color(0xFF020203);
  static const Color darkSurface = Color(0xFF0A0A0C);
  static const Color darkSurfaceAlt = Color(0xFF131316);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color darkBorderStrong = Color(0x29FFFFFF);
  static const Color darkTextPrimary = Color(0xFFEDEDEF);
  static const Color darkTextSecondary = Color(0xFFB4B7BD);
  static const Color darkTextMuted = Color(0xFF8A8F98);

  static const Gradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPrimary, brandAccent],
  );

  static const Gradient surfaceGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1B4B), Color(0xFF050506)],
  );

  static const Gradient ambientGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A0F), Color(0xFF020203)],
  );

  static Color accentGlow = brandPrimary.withValues(alpha: 0.22);

  static Color topicColor(String topic) {
    switch (topic.toLowerCase()) {
      case 'ai':
      case 'artificial intelligence':
        return const Color(0xFF8B5CF6);
      case 'startup':
      case 'startups':
        return const Color(0xFFF59E0B);
      case 'github':
      case 'open source':
        return const Color(0xFF10B981);
      case 'cybersecurity':
      case 'security':
        return const Color(0xFFEF4444);
      case 'web':
      case 'web development':
        return const Color(0xFF06B6D4);
      case 'mobile':
        return const Color(0xFF3B82F6);
      case 'blockchain':
      case 'crypto':
        return const Color(0xFFFBBF24);
      case 'robotics':
        return const Color(0xFFEC4899);
      case 'space':
      case 'space tech':
        return const Color(0xFF6366F1);
      case 'funding':
        return const Color(0xFF22C55E);
      case 'hiring':
        return const Color(0xFFA855F7);
      default:
        return brandPrimary;
    }
  }
}
