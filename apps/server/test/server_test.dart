import 'dart:convert';
import 'dart:io';

import 'package:nisabitus_server/src/database.dart';
import 'package:nisabitus_server/src/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late ServerDatabase database;
  late Handler handler;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('nisabitus_server_test_');
    database = ServerDatabase(temp.path)
      ..ensureBootstrapUser(username: 'zeke', password: 'correct horse');
    handler = NisabitusServer(database).handler;
  });

  tearDown(() {
    database.close();
    temp.deleteSync(recursive: true);
  });

  test('logs in the bootstrap user and exposes the session user', () async {
    final token = await login(handler);

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/me'),
        headers: auth(token),
      ),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, Object?>;

    expect(response.statusCode, 200);
    expect(body['username'], 'zeke');
    expect(body['isAdmin'], isTrue);
  });

  test('admin creates a family user that can log in', () async {
    final adminToken = await login(handler);

    final createResponse = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/admin/users'),
        headers: {'content-type': 'application/json', ...auth(adminToken)},
        body: jsonEncode({'username': 'maria', 'password': 'family pass'}),
      ),
    );
    final createBody =
        jsonDecode(await createResponse.readAsString()) as Map<String, Object?>;

    expect(createResponse.statusCode, 201);
    expect(createBody['username'], 'maria');
    expect(createBody['isAdmin'], isFalse);

    final mariaToken = await login(
      handler,
      username: 'maria',
      password: 'family pass',
    );
    final meResponse = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/me'),
        headers: auth(mariaToken),
      ),
    );
    final meBody =
        jsonDecode(await meResponse.readAsString()) as Map<String, Object?>;

    expect(meResponse.statusCode, 200);
    expect(meBody['username'], 'maria');
    expect(meBody['isAdmin'], isFalse);
  });

  test('non-admin users cannot create family users', () async {
    final adminToken = await login(handler);
    await createFamilyUser(handler, adminToken, 'maria');
    final mariaToken = await login(
      handler,
      username: 'maria',
      password: 'family pass',
    );

    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/admin/users'),
        headers: {'content-type': 'application/json', ...auth(mariaToken)},
        body: jsonEncode({'username': 'leo', 'password': 'family pass'}),
      ),
    );

    expect(response.statusCode, 403);
  });

  test('family users have separate backup storage', () async {
    final adminToken = await login(handler);
    await createFamilyUser(handler, adminToken, 'maria');
    final mariaToken = await login(
      handler,
      username: 'maria',
      password: 'family pass',
    );

    await importBackup(handler, adminToken, 'admin-habit');
    await importBackup(handler, mariaToken, 'maria-habit');

    final adminBackup = await exportBackup(handler, adminToken);
    final mariaBackup = await exportBackup(handler, mariaToken);

    expect(
      ((adminBackup['tables'] as Map<String, Object?>)['habits'] as List)
          .single,
      containsPair('id', 'admin-habit'),
    );
    expect(
      ((mariaBackup['tables'] as Map<String, Object?>)['habits'] as List)
          .single,
      containsPair('id', 'maria-habit'),
    );
  });

  test('answers API preflight requests with CORS headers', () async {
    final response = await handler(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/api/auth/login'),
        headers: {
          'origin': 'http://100.66.250.24:8081',
          'access-control-request-method': 'POST',
          'access-control-request-headers': 'content-type',
          'access-control-request-private-network': 'true',
        },
      ),
    );

    expect(response.statusCode, 200);
    expect(
      response.headers['access-control-allow-origin'],
      'http://100.66.250.24:8081',
    );
    expect(response.headers['access-control-allow-methods'], contains('POST'));
    expect(
      response.headers['access-control-allow-headers'],
      contains('content-type'),
    );
    expect(response.headers['access-control-allow-private-network'], 'true');
  });

  test('adds CORS headers to API responses', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/healthz'),
        headers: {'origin': 'http://100.66.250.24:8081'},
      ),
    );

    expect(response.statusCode, 200);
    expect(
      response.headers['access-control-allow-origin'],
      'http://100.66.250.24:8081',
    );
  });

  test('rejects backup export without a token', () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/api/backup/export')),
    );

    expect(response.statusCode, 401);
  });

  test(
    'imports and exports a backup document for the logged-in user',
    () async {
      final token = await login(handler);
      final backup = {
        'app': 'nisabitus',
        'format': 2,
        'schemaVersion': 14,
        'exportedAt': 1790819502408,
        'tables': {
          'habits': [
            {'id': 'habit-1', 'name': 'Meditar'},
          ],
        },
      };

      final importResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/backup/import'),
          headers: {'content-type': 'application/json', ...auth(token)},
          body: jsonEncode(backup),
        ),
      );
      final importBody = jsonDecode(
        await importResponse.readAsString(),
      ) as Map<String, Object?>;

      expect(importResponse.statusCode, 200);
      expect(importBody['rowCount'], 1);

      final exportResponse = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/api/backup/export'),
          headers: auth(token),
        ),
      );
      final exportBody = jsonDecode(
        await exportResponse.readAsString(),
      ) as Map<String, Object?>;

      expect(exportResponse.statusCode, 200);
      expect(exportBody['app'], 'nisabitus');
      expect(
        (exportBody['tables'] as Map<String, Object?>)['habits'],
        isA<List>(),
      );
    },
  );
}

Future<void> createFamilyUser(
  Handler handler,
  String adminToken,
  String username,
) async {
  final response = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/api/admin/users'),
      headers: {'content-type': 'application/json', ...auth(adminToken)},
      body: jsonEncode({'username': username, 'password': 'family pass'}),
    ),
  );
  expect(response.statusCode, 201);
}

Future<Map<String, Object?>> exportBackup(Handler handler, String token) async {
  final response = await handler(
    Request(
      'GET',
      Uri.parse('http://localhost/api/backup/export'),
      headers: auth(token),
    ),
  );
  expect(response.statusCode, 200);
  return jsonDecode(await response.readAsString()) as Map<String, Object?>;
}

Future<void> importBackup(Handler handler, String token, String habitId) async {
  final response = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/api/backup/import'),
      headers: {'content-type': 'application/json', ...auth(token)},
      body: jsonEncode({
        'app': 'nisabitus',
        'format': 2,
        'schemaVersion': 14,
        'exportedAt': 1790819502408,
        'tables': {
          'habits': [
            {'id': habitId, 'name': habitId},
          ],
        },
      }),
    ),
  );
  expect(response.statusCode, 200);
}

Future<String> login(
  Handler handler, {
  String username = 'zeke',
  String password = 'correct horse',
}) async {
  final response = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/api/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ),
  );
  final body =
      jsonDecode(await response.readAsString()) as Map<String, Object?>;
  expect(response.statusCode, 200);
  return body['token'] as String;
}

Map<String, String> auth(String token) => {'authorization': 'Bearer $token'};
