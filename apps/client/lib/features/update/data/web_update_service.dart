import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../release_notes/domain/app_version.dart';
import '../domain/update_info.dart';

/// The PWA: compares `version.json` from the server with the running build,
/// and asks the service worker whether a new version is installed and
/// waiting. Same origin, so no throttle.
class WebUpdateService implements UpdateService {
  WebUpdateService({
    required this._client,
    required Uri baseUri,
    required this._now,
    required AppVersion currentVersion,
    required this._hasWaitingWorker,
  }) : _base = baseUri,
       _current = currentVersion;

  final http.Client _client;
  final Uri _base;
  final DateTime Function() _now;
  final AppVersion _current;
  final Future<bool> Function() _hasWaitingWorker;

  @override
  Future<UpdateInfo?> check() async {
    try {
      final served = parseReleaseVersion(
        (jsonDecode(await _fetch('version.json'))
                as Map<String, dynamic>)['version']
            as String?,
      );
      final newer = served != null && served > _current;
      final waiting = await _hasWaitingWorker();
      if (!newer && !waiting) return null;

      var manifest = const UpdateManifest();
      try {
        manifest = UpdateManifest.parse(await _fetch('update.json'));
      } on Object {
        // Missing manifest: no schema change assumed.
      }

      return UpdateInfo(
        latest: newer ? served : _current,
        url: _base,
        schemaChange: manifest.schemaChange,
        minSupportedVersion: manifest.minSupportedVersion,
      );
    } on Object {
      return null;
    }
  }

  Future<String> _fetch(String file) async {
    final url = _base
        .resolve(file)
        .replace(queryParameters: {'t': '${_now().millisecondsSinceEpoch}'});
    final response = await _client.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', url);
    }
    return response.body;
  }
}
