import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';

class NisabitusServer {
  NisabitusServer(this.database, {this.publicDir});

  final ServerDatabase database;
  final String? publicDir;

  Handler get handler {
    final router = Router()
      ..get('/healthz', _health)
      ..post('/api/auth/login', _login)
      ..post('/api/auth/logout', _logout)
      ..get('/api/me', _me)
      ..post('/api/admin/users', _createUser)
      ..get('/api/backup/export', _exportBackup)
      ..post('/api/backup/import', _importBackup);

    final api = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_cors())
        .addMiddleware(_jsonErrors())
        .addHandler(router.call);
    final static = publicDir == null
        ? _notFound
        : createStaticHandler(publicDir!, defaultDocument: 'index.html');

    return Cascade().add(api).add(static).handler;
  }

  Response _health(Request request) => _json({'ok': true});

  Future<Response> _login(Request request) async {
    final body = await _readJson(request);
    final username = body['username'];
    final password = body['password'];
    if (username is! String || password is! String) {
      return _json({
        'error': 'username and password are required',
      }, status: HttpStatus.badRequest);
    }

    final token = database.login(username: username, password: password);
    if (token == null) {
      return _json({
        'error': 'invalid credentials',
      }, status: HttpStatus.unauthorized);
    }
    final user = database.userForToken(token)!;
    return _json({'token': token, 'user': _userJson(user)});
  }

  Response _logout(Request request) {
    final token = _bearerToken(request);
    if (token != null) database.logout(token);
    return _json({'ok': true});
  }

  Response _me(Request request) {
    final user = _requireUser(request);
    if (user == null) return _unauthorized();
    return _json(_userJson(user));
  }

  Future<Response> _createUser(Request request) async {
    final user = _requireUser(request);
    if (user == null) return _unauthorized();
    if (!user.isAdmin) {
      return _json({'error': 'admin required'}, status: HttpStatus.forbidden);
    }

    final body = await _readJson(request);
    final username = body['username'];
    final password = body['password'];
    if (username is! String || password is! String) {
      return _json({
        'error': 'username and password are required',
      }, status: HttpStatus.badRequest);
    }

    try {
      final created = database.createUser(
        username: username,
        password: password,
      );
      return _json(_userJson(created), status: HttpStatus.created);
    } on SqliteException catch (error) {
      if (error.extendedResultCode == 2067 || error.resultCode == 19) {
        return _json({
          'error': 'username already exists',
        }, status: HttpStatus.conflict);
      }
      rethrow;
    } on ArgumentError catch (error) {
      return _json({'error': error.message}, status: HttpStatus.badRequest);
    }
  }

  Response _exportBackup(Request request) {
    final user = _requireUser(request);
    if (user == null) return _unauthorized();
    return Response.ok(
      database.exportDocument(user.id),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<Response> _importBackup(Request request) async {
    final user = _requireUser(request);
    if (user == null) return _unauthorized();

    final body = await _readJson(request);
    try {
      final result = database.importDocument(user.id, body);
      return _json({
        'rowCount': result.rowCount,
        'updatedAt': result.updatedAt.toIso8601String(),
      });
    } on FormatException catch (error) {
      return _json({'error': error.message}, status: HttpStatus.badRequest);
    }
  }

  Response _notFound(Request request) =>
      _json({'error': 'not found'}, status: HttpStatus.notFound);

  UserRecord? _requireUser(Request request) {
    final token = _bearerToken(request);
    return token == null ? null : database.userForToken(token);
  }

  String? _bearerToken(Request request) {
    final value = request.headers['authorization'];
    if (value == null) return null;
    final parts = value.split(' ');
    if (parts.length != 2 || parts.first.toLowerCase() != 'bearer') return null;
    return parts.last;
  }

  Future<Map<String, Object?>> _readJson(Request request) async {
    final source = await request.readAsString();
    final decoded = jsonDecode(source.isEmpty ? '{}' : source);
    if (decoded is Map<String, Object?>) return decoded;
    throw const FormatException('JSON object expected');
  }

  Map<String, Object?> _userJson(UserRecord user) => {
    'id': user.id,
    'username': user.username,
    'isAdmin': user.isAdmin,
  };

  Response _unauthorized() => _json({
    'error': 'authentication required',
  }, status: HttpStatus.unauthorized);

  Response _json(Object body, {int status = HttpStatus.ok}) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Middleware _cors() => (inner) {
  return (request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: _corsHeaders(request));
    }

    final response = await inner(request);
    return response.change(headers: _corsHeaders(request));
  };
};

Map<String, String> _corsHeaders(Request request) {
  final origin = request.headers['origin'];
  return {
    'access-control-allow-origin': origin == null || origin.isEmpty
        ? '*'
        : origin,
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-max-age': '86400',
    'vary': 'Origin',
  };
}

Middleware _jsonErrors() => (inner) {
  return (request) async {
    try {
      return await inner(request);
    } on FormatException catch (error) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode({'error': error.message}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  };
};
