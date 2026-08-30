// lib/services/api_client.dart
//
// Thin wrapper around package:http that all repositories/services use to
// talk to the Node/Express backend. Handles:
//  - attaching the JWT bearer token (read from SharedPreferences)
//  - JSON encode/decode
//  - unwrapping the backend's standard { success, message, data } envelope
//  - multipart uploads (resume, profile image)
//  - normalized errors via [ApiException]

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/app_state.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String tokenKey = 'cm_jwt_token';

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final t = await token;
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final full = path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    final cleaned = <String, String>{};
    query.forEach((k, v) {
      if (v != null) cleaned[k] = v.toString();
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...cleaned});
  }

  /// Unwraps `{success, message, data, pagination?}` and throws
  /// [ApiException] on network failure, non-2xx status, or `success: false`.
  dynamic _handle(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected response from server (${res.statusCode})', res.statusCode);
    }

    final success = body['success'] == true;
    if (res.statusCode >= 200 && res.statusCode < 300 && success) {
      return body; // caller pulls ['data'] / ['pagination'] as needed
    }

    final message = (body['message'] as String?) ?? 'Request failed (${res.statusCode})';

    // A 401 here means the JWT is missing/expired/invalid (as opposed to a
    // 403, which is a role/permission issue on a still-valid session).
    // Clear the stored token and flip the global auth flag so HomeShell's
    // existing guard redirects to the Login screen automatically, instead
    // of leaving the user stuck on a broken screen with a stale session.
    if (res.statusCode == 401) {
      clearToken();
      AppState.instance.clearSession();
    }

    throw ApiException(message, res.statusCode);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .get(_uri(path, query), headers: await _headers())
          .timeout(const Duration(seconds: 20));
      return _handle(res);
    } on SocketException {
      throw ApiException('Could not reach the server. Check your connection and that the backend is running.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .post(_uri(path, query), headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 20));
      return _handle(res);
    } on SocketException {
      throw ApiException('Could not reach the server. Check your connection and that the backend is running.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .put(_uri(path, query), headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 20));
      return _handle(res);
    } on SocketException {
      throw ApiException('Could not reach the server. Check your connection and that the backend is running.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .delete(_uri(path, query), headers: await _headers())
          .timeout(const Duration(seconds: 20));
      return _handle(res);
    } on SocketException {
      throw ApiException('Could not reach the server. Check your connection and that the backend is running.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// Multipart upload (resume / profile image / certificate). [fieldName]
  /// must match the backend multer field name (e.g. 'resume', 'image',
  /// 'certificate'). Optional [fields] are sent as additional form fields
  /// alongside the file (e.g. certificate title/issuer/issueDate).
  Future<dynamic> uploadFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    String method = 'POST',
    Map<String, String>? fields,
  }) async {
    try {
      final request = http.MultipartRequest(method, _uri(path));
      final headers = await _headers(json: false);
      request.headers.addAll(headers);
      if (fields != null) request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on SocketException {
      throw ApiException('Could not reach the server. Check your connection and that the backend is running.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Upload failed: $e');
    }
  }
}
