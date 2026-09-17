import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';
import 'package:nisabitus/features/update/data/web_update_service.dart';

void main() {
  final base = Uri.parse('https://iezappa.github.io/nisabitus/');

  WebUpdateService service({
    String version = '1.2.0',
    bool waiting = false,
    bool offline = false,
  }) => WebUpdateService(
    client: MockClient((request) async {
      if (offline) throw http.ClientException('offline');
      expect(request.url.queryParameters, contains('t'));
      if (request.url.path.endsWith('version.json')) {
        return http.Response('{"version":"$version","build_number":"3"}', 200);
      }
      return http.Response('{"schemaChange":true}', 200);
    }),
    baseUri: base,
    now: () => DateTime(2026, 9, 17),
    currentVersion: const AppVersion(1, 2, 0),
    hasWaitingWorker: () async => waiting,
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
}
