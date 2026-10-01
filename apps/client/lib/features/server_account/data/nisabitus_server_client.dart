import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../backup/domain/backup_document.dart';

class ServerAccountException implements Exception {
  const ServerAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LoginResult {
  const LoginResult({required this.token, required this.username});

  final String token;
  final String username;
}

class ServerImportResult {
  const ServerImportResult({required this.rowCount});

  final int rowCount;
}

class NisabitusServerClient {
  NisabitusServerClient({required String baseUrl, http.Client? client})
    : _baseUri = _normalizeBaseUri(baseUrl),
      _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  static Uri _normalizeBaseUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const ServerAccountException('Server URL is required');
    }
    final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      throw const ServerAccountException('Server URL is not valid');
    }
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }

  Uri _resolve(String path) => _baseUri.resolve(path);

  Future<void> healthCheck() async {
    final response = await _client
        .get(_resolve('healthz'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw ServerAccountException(
        'Server health check failed (${response.statusCode})',
      );
    }
  }

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          _resolve('api/auth/login'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw ServerAccountException('Login failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['token'] is! String) {
      throw const ServerAccountException('Login response is not valid');
    }
    return LoginResult(token: decoded['token'] as String, username: username);
  }

  Future<void> logout(String token) async {
    await _client
        .post(_resolve('api/auth/logout'), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 8));
  }

  Future<BackupDocument> downloadBackup({
    required String token,
    required int supportedSchemaVersion,
  }) async {
    final response = await _client
        .get(_resolve('api/backup/export'), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ServerAccountException('Download failed (${response.statusCode})');
    }
    return BackupDocument.parse(
      response.body,
      supportedSchemaVersion: supportedSchemaVersion,
    );
  }

  Future<ServerImportResult> uploadBackup({
    required String token,
    required BackupDocument document,
  }) async {
    final response = await _client
        .post(
          _resolve('api/backup/import'),
          headers: {..._authHeaders(token), 'content-type': 'application/json'},
          body: document.encode(),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ServerAccountException('Upload failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['rowCount'] is! int) {
      throw const ServerAccountException('Upload response is not valid');
    }
    return ServerImportResult(rowCount: decoded['rowCount'] as int);
  }

  Map<String, String> _authHeaders(String token) => {
    'authorization': 'Bearer $token',
  };
}
