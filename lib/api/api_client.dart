import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// An error returned by the API. The server always answers errors as
/// { "error": { "message": "...", "details": {...} } } (SDD 3.12), so the
/// message can be shown to the user as it is.
class ApiException implements Exception {
  final int status;
  final String message;
  final Map<String, dynamic> details;

  ApiException(this.status, this.message, [Map<String, dynamic>? details]) : details = details ?? const {};

  /// Field-level validation messages from the validate middleware,
  /// e.g. {"email": "Enter a valid email address."}
  Map<String, String> get fieldErrors {
    final fields = details['fields'];
    if (fields is Map) return fields.map((k, v) => MapEntry('$k', '$v'));
    return const {};
  }

  @override
  String toString() => message;
}

/// Thin wrapper around package:http that adds the JWT, decodes JSON and turns
/// error responses into [ApiException]s. Every screen goes through this one class.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // The JWT lives in the phone's secure storage (Android Keystore / iOS Keychain),
  // never in plain shared preferences.
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'eventify_token';

  String? _token;
  String? get token => _token;

  /// Called when the server says the token is no longer valid (expired or
  /// logged out elsewhere). The session listens to this and returns to login.
  void Function()? onUnauthorized;

  Future<String?> loadToken() async => _token = await _storage.read(key: _tokenKey);

  Future<void> saveToken(String? value) async {
    _token = value;
    if (value == null) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: value);
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?..removeWhere((k, v) => v == null || v == '');
    return Uri.parse('${AppConfig.apiUrl}$path').replace(queryParameters: q == null || q.isEmpty ? null : q.map((k, v) => MapEntry(k, '$v')));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, [Object? body]) => _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) => _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  /// Multipart upload (profile photo). [field] is the form field the server expects.
  Future<dynamic> upload(String path, String field, File file) => _send(() async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({'Accept': 'application/json', if (_token != null) 'Authorization': 'Bearer $_token'})
      ..files.add(await http.MultipartFile.fromPath(field, file.path));
    return http.Response.fromStream(await req.send());
  });

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to answer. Check your connection and try again.');
    } on SocketException {
      throw ApiException(0, 'No connection. Check your internet and try again.');
    } on http.ClientException {
      throw ApiException(0, 'Could not reach Eventify. Check your internet and try again.');
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final err = data is Map ? data['error'] : null;
    final message = err is Map && err['message'] != null ? '${err['message']}' : 'Something went wrong (${res.statusCode}).';
    final details = err is Map && err['details'] is Map ? Map<String, dynamic>.from(err['details']) : null;
    // 401 = missing/expired/revoked token. Only treat it as a logout when we had a token.
    if (res.statusCode == 401 && _token != null) onUnauthorized?.call();
    throw ApiException(res.statusCode, message, details);
  }
}

/// Short alias used by the screens: `api.get('/events')`.
final api = ApiClient.instance;
