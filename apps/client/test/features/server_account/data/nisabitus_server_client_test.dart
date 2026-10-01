import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nisabitus/features/backup/domain/backup_document.dart';
import 'package:nisabitus/features/server_account/data/nisabitus_server_client.dart';

void main() {
  test('logs in against the configured server', () async {
    final client = NisabitusServerClient(
      baseUrl: 'http://server.local:5051',
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://server.local:5051/api/auth/login',
        );
        expect(jsonDecode(request.body), {
          'username': 'admin',
          'password': 'secret123',
        });
        return http.Response(jsonEncode({'token': 'abc'}), 200);
      }),
    );

    final result = await client.login(username: 'admin', password: 'secret123');

    expect(result.token, 'abc');
    expect(result.username, 'admin');
  });

  test('adds http when the server URL has no scheme', () async {
    final client = NisabitusServerClient(
      baseUrl: 'zima.local:5051',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://zima.local:5051/healthz');
        return http.Response('{"ok":true}', 200);
      }),
    );

    await client.healthCheck();
  });

  test('uploads the backup document with bearer auth', () async {
    final client = NisabitusServerClient(
      baseUrl: 'http://server.local:5051',
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer token');
        expect(request.url.path, '/api/backup/import');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['app'], 'nisabitus');
        return http.Response(jsonEncode({'rowCount': 1}), 200);
      }),
    );

    final result = await client.uploadBackup(
      token: 'token',
      document: BackupDocument(
        schemaVersion: 1,
        exportedAt: DateTime(2026, 1, 1),
        tables: const {
          'habits': [
            {'id': 'h1'},
          ],
        },
      ),
    );

    expect(result.rowCount, 1);
  });
}
