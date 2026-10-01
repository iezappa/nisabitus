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

Future<String> login(Handler handler) async {
  final response = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/api/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'username': 'zeke', 'password': 'correct horse'}),
    ),
  );
  final body =
      jsonDecode(await response.readAsString()) as Map<String, Object?>;
  expect(response.statusCode, 200);
  return body['token'] as String;
}

Map<String, String> auth(String token) => {'authorization': 'Bearer $token'};
