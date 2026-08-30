// lib/config/auth_colors.dart
//
// IMPORTANT INTEGRATION NOTE
// ---------------------------------------------------------------------
// Career Matrix already has a Blue & White theme defined somewhere in the
// existing project (e.g. lib/theme/app_theme.dart or lib/constants/colors.dart).
//
// This file is a SAFE FALLBACK ONLY, so the auth module can be dropped in
// and compiled/previewed independently without touching your existing
// theme files. Before final integration:
//
//   1. Open your existing theme/colors file.
//   2. Replace every `AuthColors.xxx` reference inside lib/screens/auth
//      and lib/widgets/auth with your existing `AppColors.xxx` (or
//      equivalent) constants.
//   3. Delete this file once no longer referenced.
//
// The values below intentionally match a typical professional Blue &
// White palette so screens look correct even before that swap happens.
// ---------------------------------------------------------------------

import 'package:flutter/material.dart';

class AuthColors {
  AuthColors._();

  static const Color primaryBlue = Color(0xFF1657D0);
  static const Color darkBlue = Color(0xFF0D3E9E);
  static const Color lightBlue = Color(0xFFE8F0FE);
  static const Color accentBlue = Color(0xFF4A90E2);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E6ED);

  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF1E9E63);
}
