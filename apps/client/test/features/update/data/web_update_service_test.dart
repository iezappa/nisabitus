import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';
import 'package:nisabitus/features/update/data/web_update_service.dart';

void main() {
  final base = Uri.parse('https://iezappa.github.io/nisabitus/');

  final problems = <String>[];
  setUp(problems.clear);

  WebUpdateService service({
    String version = '1.2.0',
    bool waiting = false,
    bool offline = false,
    String? rawVersionJson,
  }) => WebUpdateService(
    client: MockClient((request) async {
      if (offline) throw http.ClientException('offline');
      expect(request.url.queryParameters, contains('t'));
      if (request.url.path.endsWith('version.json')) {
        return http.Response(
          rawVersionJson ?? '{"version":"$version","build_number":"3"}',
          200,
        );
      }
      return http.Response('{"schemaChange":true}', 200);
    }),
    baseUri: base,
    now: () => DateTime(2026, 9, 17),
    currentVersion: const AppVersion(1, 2, 0),
    hasWaitingWorker: () async => waiting,
    onProblem: (what, cause) => problems.add(what),
  );

  test('reports a newer version.json, with update.json flags', () async {
    final info = await service(version: '1.3.0').check();
    expect(info!.latest, const AppVersion(1, 3, 0));
    expect(info.schemaChange, isTrue);
    expect(info.url, base);
  });

  test('reports a waiting service worker even at the same version', () async {
    expect(await service(waiting: true).check(), isNotNull);
  });

  test('is silent when nothing changed', () async {
    expect(await service().check(), isNull);
  });

  test('is silent offline', () async {
    expect(await service(offline: true).check(), isNull);
  });

  test(
    'is silent offline and says nothing was wrong with the answer',
    () async {
      expect(await service(offline: true).check(), isNull);
      expect(
        problems,
        isEmpty,
        reason: 'no network is normal, not something to look into',
      );
    },
  );

  // A malformed answer is silence to the user like any other failure — there
  // is nothing they could do about it — but it is a server that is broken and
  // stays broken, so it is written down rather than lost.
  test('records a version.json that is not JSON at all', () async {
    expect(await service(rawVersionJson: '<html>502</html>').check(), isNull);
    expect(problems, ['version.json']);
  });

  test('records a version.json with no readable version', () async {
    expect(
      await service(rawVersionJson: '{"build_number":"3"}').check(),
      isNull,
    );
    expect(problems, ['version.json']);
  });

  test('records a version that is not a release number', () async {
    expect(await service(version: 'nightly').check(), isNull);
    expect(problems, ['version.json']);
  });

  test('says nothing when the answer reads perfectly well', () async {
    await service(version: '1.3.0').check();
    expect(problems, isEmpty);
  });
}
