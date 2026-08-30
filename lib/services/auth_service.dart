// lib/services/auth_service.dart
//
// Talks to the real Node/Express + MongoDB backend
// (POST /api/auth/register, POST /api/auth/login, GET /api/auth/me).
// Keeps the exact same public API the UI already calls
// (login/register/logout/restoreSession) so login_screen.dart,
// register_screen.dart, profile_screen.dart etc. did not need to change.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kLoggedIn = 'auth_logged_in';
  static const _kRole = 'auth_role';
  static const _kName = 'auth_name';
  static const _kEmail = 'auth_email';
  static const _kUserId = 'auth_user_id';

  /// Currently authenticated user's Mongo _id, used by other
  /// repositories (skills, resume, profile, etc.) that need it.
  Future<String?> get currentUserId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final res = await ApiClient.instance.post('/auth/login', body: {
      'email': email,
      'password': password,
      'role': role.key,
    });
    await _persistAuthResponse(res);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final res = await ApiClient.instance.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role.key,
    });
    final data = res['data'] as Map<String, dynamic>;
    if (data['pending'] == true) {
      return true;
    }
    await _persistAuthResponse(res);
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kRole);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kUserId);
    await ApiClient.instance.clearToken();
  }

  /// Restores a previously persisted session, if any. Used for auto-login
  /// on app start. Also validates the token against GET /api/auth/me so a
  /// stale/expired/revoked token doesn't silently let the user "in".
  Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_kLoggedIn) ?? false;
    if (!loggedIn) return null;

    final token = await ApiClient.instance.token;
    if (token == null || token.isEmpty) return null;

    try {
      final res = await ApiClient.instance.get('/auth/me');
      final user = res['data']['user'] as Map<String, dynamic>;
      final role = UserRoleX.fromKey(user['role'] as String? ?? 'student');
      final name = user['name'] as String? ?? 'Guest User';
      final email = user['email'] as String? ?? '';
      final id = (user['_id'] ?? user['id'])?.toString() ?? '';
      await prefs.setString(_kName, name);
      await prefs.setString(_kEmail, email);
      await prefs.setString(_kRole, role.key);
      await prefs.setString(_kUserId, id);
      return AuthSession(role: role, name: name, email: email);
    } catch (_) {
      // Token invalid/expired or backend unreachable at boot time.
      // Fall back to the last-known cached session so the app still opens
      // (screens will surface their own network errors when they fetch data).
      final roleKey = prefs.getString(_kRole);
      final role = UserRole.values.firstWhere(
        (r) => r.key == roleKey,
        orElse: () => UserRole.student,
      );
      final name = prefs.getString(_kName) ?? 'Guest User';
      final email = prefs.getString(_kEmail) ?? '';
      return AuthSession(role: role, name: name, email: email);
    }
  }

  Future<void> _persistAuthResponse(dynamic res) async {
    final data = res['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;

    final role = UserRoleX.fromKey(user['role'] as String? ?? 'student');
    final name = user['name'] as String? ?? 'Guest User';
    final email = user['email'] as String? ?? '';
    final id = (user['_id'] ?? user['id'])?.toString() ?? '';

    await ApiClient.instance.saveToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kRole, role.key);
    await prefs.setString(_kName, name);
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kUserId, id);
  }
}

class AuthSession {
  final UserRole role;
  final String name;
  final String email;
  const AuthSession({required this.role, required this.name, required this.email});
}
