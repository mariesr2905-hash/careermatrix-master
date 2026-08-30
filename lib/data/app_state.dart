import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Minimal global app state — deliberately dependency-free (no provider /
/// riverpod) since this is a frontend-only scaffold. Swap for your preferred
/// state management solution when wiring up the backend.
class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<UserRole> currentRole = ValueNotifier(UserRole.student);
  final ValueNotifier<bool> onboardingSeen = ValueNotifier(false);

  /// True once a session has been established (via login, registration, or
  /// auto-login on app start) and cleared again on logout. HomeShell (and
  /// anything reached through it) treats this as the source of truth for
  /// route protection.
  final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
  final ValueNotifier<String> userName = ValueNotifier('Guest User');
  final ValueNotifier<String> userEmail = ValueNotifier('');

  void applySession({required UserRole role, required String name, required String email}) {
    currentRole.value = role;
    userName.value = name;
    userEmail.value = email;
    isAuthenticated.value = true;
  }

  void clearSession() {
    isAuthenticated.value = false;
    userName.value = 'Guest User';
    userEmail.value = '';
  }
}
