import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';
import 'package:nisabitus/features/update/data/github_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;
  var calls = 0;
  final problems = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 9, 17, 12);
    calls = 0;
    problems.clear();
  });

  String release({String tag = 'v1.3.0', bool apk = true}) => jsonEncode({
    'tag_name': tag,
    'html_url': 'https://github.com/iezappa/nisabitus/releases/tag/$tag',
    'body': 'Notas',
    'assets': [
      if (apk)
        {
          'name': 'nisabitus-$tag-android.apk',
          'browser_download_url': 'https://example.org/app.apk',
        },
      {
        'name': 'update.json',
        'browser_download_url': 'https://example.org/update.json',
      },
    ],
  });

  GitHubUpdateService service({
    String current = '1.2.0',
    bool android = false,
    http.Client? client,
  }) => GitHubUpdateService(
    client:
        client ??
        MockClient((request) async {
          calls++;
          if (request.url.path.endsWith('update.json')) {
            return http.Response(
              '{"version":"1.3.0","schemaChange":true}',
              200,
            );
          }
          expect(request.url.toString(), GitHubUpdateService.latestReleaseUrl);
          return http.Response(release(), 200);
        }),
    prefs: prefs,
    now: () => now,
    currentVersion: AppVersion.parse(current),
    isAndroid: android,
    onProblem: (what, cause) => problems.add(what),
  );

  test('reports a newer release with its page and schema flag', () async {
    final info = await service().check();

    expect(info!.latest, const AppVersion(1, 3, 0));
    expect(info.url.toString(), contains('/releases/tag/v1.3.0'));
    expect(info.schemaChange, isTrue);
    expect(info.notes, 'Notas');
  });

  test('points Android at the APK asset', () async {
    final info = await service(android: true).check();
    expect(info!.url.toString(), 'https://example.org/app.apk');
  });

  test('says nothing when the release is not newer', () async {
    expect(await service(current: '1.3.0').check(), isNull);
  });

  group('throttle', () {
    test('checks when it never has', () async {
      await service().check();
      expect(calls, greaterThan(0));
    });

    test('does not check again within six hours', () async {
      await service().check();
      calls = 0;
      now = now.add(const Duration(hours: 5));

      expect(await service().check(), isNull);
      expect(calls, 0);
    });

    test('checks again after six hours', () async {
      await service().check();
      calls = 0;
      now = now.add(const Duration(hours: 7));

      await service().check();
      expect(calls, greaterThan(0));
    });
  });

  test('a network error is null, never an exception', () async {
    final failing = MockClient((_) async => throw http.ClientException('off'));
    expect(await service(client: failing).check(), isNull);
    expect(problems, isEmpty, reason: 'no network is normal');
  });

  test('a server error is null', () async {
    final failing = MockClient((_) async => http.Response('', 500));
    expect(await service(client: failing).check(), isNull);
    expect(problems, isEmpty, reason: 'a 500 is the server having a bad day');
  });

  // Silence to the user either way — there is nothing they could do — but a
  // release whose shape this app cannot read stays unreadable until somebody
  // is told, and every check after it would be silent for the wrong reason.
  test('records an answer that is not JSON', () async {
    final broken = MockClient((_) async => http.Response('<html>', 200));
    expect(await service(client: broken).check(), isNull);
    expect(problems, ['the GitHub release']);
  });

  test('records a release whose tag is not a version', () async {
    final broken = MockClient(
      (_) async => http.Response(release(tag: 'latest'), 200),
    );
    expect(await service(client: broken).check(), isNull);
    expect(problems, ['the GitHub release']);
  });

  test('says nothing about a release it read perfectly well', () async {
    await service().check();
    expect(problems, isEmpty);
  });
}
