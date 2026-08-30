// lib/utils/app_constants.dart
//
// Central place for auth-module constants.
// NOTE: When the Node.js + Express + MongoDB backend is ready, only
// [AppConstants.baseUrl] and the endpoint paths need to change.

/// The five supported roles in Career Matrix.
enum UserRole { student, alumni, mentor, company, administrator }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.alumni:
        return 'Alumni';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.company:
        return 'Company';
      case UserRole.administrator:
        return 'Administrator';
    }
  }

  /// Value sent to / received from the backend.
  String get apiValue => name; // student, alumni, mentor, company, administrator

  static UserRole fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.apiValue.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.student,
    );
  }
}

class AppConstants {
  AppConstants._();

  /// Placeholder base URL for the future Node/Express/MongoDB backend.
  /// Swap this for the real API host when backend work begins.
  static const String baseUrl = 'https://api.careermatrix.example.com/api/v1';

  // ---- Auth endpoints (not called yet, service layer is mocked) ----
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';

  // ---- Local storage keys ----
  static const String keyAuthToken = 'cm_auth_token';
  static const String keyRefreshToken = 'cm_refresh_token';
  static const String keyUser = 'cm_user';
  static const String keyRememberMe = 'cm_remember_me';
  static const String keyTokenExpiry = 'cm_token_expiry';

  // ---- Misc ----
  static const int otpLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 30);

  /// Simulated JWT lifetime used by the mock service so the
  /// "auto redirect to login on session expiry" flow can be demoed
  /// before a real backend exists.
  static const Duration mockSessionLifetime = Duration(hours: 12);
}
