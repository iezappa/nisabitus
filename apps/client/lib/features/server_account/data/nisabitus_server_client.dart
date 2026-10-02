import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../backup/domain/backup_document.dart';

class ServerAccountException implements Exception {
  const ServerAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ServerUser {
  const ServerUser({
    required this.id,
    required this.username,
    required this.isAdmin,
  });

  final String id;
  final String username;
  final bool isAdmin;

  static ServerUser fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['username'] is! String ||
        value['isAdmin'] is! bool) {
      throw const ServerAccountException('User response is not valid');
    }
    return ServerUser(
      id: value['id'] as String,
      username: value['username'] as String,
      isAdmin: value['isAdmin'] as bool,
    );
  }
}

class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final ServerUser user;
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
    return LoginResult(
      token: decoded['token'] as String,
      user: ServerUser.fromJson(decoded['user']),
    );
  }

  Future<ServerUser> createUser({
    required String token,
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          _resolve('api/admin/users'),
          headers: {..._authHeaders(token), 'content-type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 201) {
      throw ServerAccountException(
        _errorMessage(response, fallback: 'Create user failed'),
      );
    }
    return ServerUser.fromJson(jsonDecode(response.body));
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

  String _errorMessage(http.Response response, {required String fallback}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on Object {
      // Keep the status-code fallback when the server did not return JSON.
    }
    return '$fallback (${response.statusCode})';
  }

  Map<String, String> _authHeaders(String token) => {
    'authorization': 'Bearer $token',
  };
}
