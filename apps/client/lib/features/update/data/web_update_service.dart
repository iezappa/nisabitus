import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../release_notes/domain/app_version.dart';
import '../domain/update_info.dart';
import 'update_check_problem.dart';

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
    UpdateCheckProblemReporter onProblem = reportUpdateCheckProblem,
  }) : _base = baseUri,
       _current = currentVersion,
       _onProblem = onProblem;

  final http.Client _client;
  final Uri _base;
  final DateTime Function() _now;
  final AppVersion _current;
  final Future<bool> Function() _hasWaitingWorker;
  final UpdateCheckProblemReporter _onProblem;

  @override
  Future<UpdateInfo?> check() async {
    // Two failures that look identical to the user and are nothing alike to
    // whoever ships the app: the fetch not arriving, which is normal and
    // fixes itself, and the fetch arriving in a shape this app cannot read,
    // which does not. Only the second is written down.
    final String body;
    try {
      body = await _fetch('version.json');
    } on Object {
      return null;
    }

    final AppVersion? served;
    try {
      served = parseReleaseVersion(
        (jsonDecode(body) as Map<String, dynamic>)['version'] as String?,
      );
      if (served == null) {
        throw const FormatException('no readable "version"');
      }
    } on Object catch (error) {
      _onProblem('version.json', error);
      return null;
    }

    try {
      final newer = served > _current;
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
