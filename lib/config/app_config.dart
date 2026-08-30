// lib/config/app_config.dart
//
// Central place for backend connectivity configuration.
//
// IMPORTANT for real devices / physical phones:
// 'localhost' / '10.0.2.2' only work for emulators/simulators running on the
// SAME machine as the backend. If you run the app on a real phone, replace
// [AppConfig.baseUrl] below with your computer's LAN IP, e.g.
// 'http://192.168.1.25:5000/api', and make sure the phone is on the same
// Wi-Fi network as the backend.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Host + port the Node/Express backend is running on (see backend/.env -> PORT).
  static const int _backendPort = 5000;

  /// Resolves the correct host for the current platform so
  /// `flutter run` works out of the box in the common local-dev cases:
  /// - Chrome / web                -> localhost
  /// - Android emulator            -> 10.0.2.2 (emulator's alias for host machine)
  /// - iOS simulator / macOS/Windows/Linux desktop -> localhost
  static String get _host {
    if (kIsWeb) return 'localhost';
    try {
    if (Platform.isAndroid) return 'localhost';
    } catch (_) {
      // Platform.* throws on web, already handled by the kIsWeb check above.
    }
    return 'localhost';
  }

  /// Base URL for every API call, e.g. http://10.0.2.2:5000/api
  ///
  /// Override at build/run time without touching code:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.25:5000/api
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return 'http://$_host:$_backendPort/api';
  }

  /// Base URL (no /api) used to build absolute links to uploaded files
  /// (resumes, profile images) served from backend's /uploads static route.
  static String get fileBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override.endsWith('/api') ? override.substring(0, override.length - 4) : override;
    }
    return 'http://$_host:$_backendPort';
  }
}
