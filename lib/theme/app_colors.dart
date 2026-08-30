import 'package:flutter/material.dart';

/// Career Matrix brand palette — Professional Blue & White.
class AppColors {
  AppColors._();

  // Core brand blues
  static const Color primary = Color(0xFF1957E0);
  static const Color primaryDark = Color(0xFF0E3A9E);
  static const Color primaryDeep = Color(0xFF0A2A73);
  static const Color primaryLight = Color(0xFF4B83F0);
  static const Color primarySoft = Color(0xFFEAF1FF);
  static const Color primarySoft2 = Color(0xFFDCE9FF);

  // Accent
  static const Color accentCyan = Color(0xFF15C4D9);
  static const Color accentIndigo = Color(0xFF6C63FF);

  // Neutrals
  static const Color background = Color(0xFFF6F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5FB);
  static const Color border = Color(0xFFE4EBF8);

  static const Color textPrimary = Color(0xFF0E1B33);
  static const Color textSecondary = Color(0xFF5B6B85);
  static const Color textMuted = Color(0xFF677289);

  // Status
  static const Color success = Color(0xFF17B26A);
  static const Color successSoft = Color(0xFFE4F8EE);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningSoft = Color(0xFFFDF1DD);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFDE8E8);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E3A9E), Color(0xFF1957E0), Color(0xFF3B82F6)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAF1FF), Color(0xFFF6F9FF)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15C4D9), Color(0xFF1957E0)],
  );

  static LinearGradient roleGradient(String key) {
    switch (key) {
      case 'student':
        return const LinearGradient(colors: [Color(0xFF1957E0), Color(0xFF4B83F0)]);
      case 'alumni':
        return const LinearGradient(colors: [Color(0xFF0A2A73), Color(0xFF1957E0)]);
      case 'mentor':
        return const LinearGradient(colors: [Color(0xFF15C4D9), Color(0xFF1957E0)]);
      case 'company':
        return const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF1957E0)]);
      case 'admin':
        return const LinearGradient(colors: [Color(0xFF0E1B33), Color(0xFF1957E0)]);
      default:
        return heroGradient;
    }
  }
}
