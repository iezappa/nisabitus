import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../release_notes/domain/app_version.dart';
import '../domain/update_info.dart';
import 'update_check_problem.dart';

/// Native builds (Android, Windows, Linux, macOS): asks GitHub Releases.
///
/// Unauthenticated, so GitHub allows 60 requests an hour per IP. The check
/// runs at most once every six hours, with a short timeout, and any failure
/// is silence. No token is ever embedded.
class GitHubUpdateService implements UpdateService {
  GitHubUpdateService({
    required this._client,
    required this._prefs,
    required this._now,
    required AppVersion currentVersion,
    required this._isAndroid,
    UpdateCheckProblemReporter onProblem = reportUpdateCheckProblem,
  }) : _current = currentVersion,
       // A named parameter cannot be written `this._onProblem`.
       // ignore: prefer_initializing_formals
       _onProblem = onProblem;

  static const latestReleaseUrl =
      'https://api.github.com/repos/iezappa/nisabitus/releases/latest';
  static const lastCheckKey = 'update.lastCheckAt';
  static const throttle = Duration(hours: 6);
  static const timeout = Duration(seconds: 5);

  final http.Client _client;
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final AppVersion _current;
  final bool _isAndroid;
  final UpdateCheckProblemReporter _onProblem;

  @override
  Future<UpdateInfo?> check() async {
    final now = _now();
    final last = DateTime.tryParse(_prefs.getString(lastCheckKey) ?? '');
    if (last != null && now.difference(last) < throttle) return null;
    await _prefs.setString(lastCheckKey, now.toIso8601String());

    // Not reaching GitHub is normal — offline, rate limited, a bad day at
    // the API — and fixes itself. An answer this app cannot read does not:
    // that is a release published in a shape the update check does not
    // understand, and nobody would ever hear about it. Only the second is
    // written down; the user sees the same silence either way.
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(latestReleaseUrl),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(timeout);
    } on Object {
      return null;
    }
    if (response.statusCode != 200) return null;

    final Map<String, dynamic> json;
    final AppVersion latest;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = parseReleaseVersion(json['tag_name'] as String?);
      if (tag == null) {
        throw FormatException('unreadable tag_name', json['tag_name']);
      }
      latest = tag;
    } on Object catch (error) {
      _onProblem('the GitHub release', error);
      return null;
    }
    if (!(latest > _current)) return null;

    try {
      final assets = [
        for (final asset in (json['assets'] as List? ?? const []))
          if (asset is Map<String, dynamic>) asset,
      ];
      String? assetUrl(bool Function(String name) matches) {
        for (final asset in assets) {
          if (matches(asset['name'] as String? ?? '')) {
            return asset['browser_download_url'] as String?;
          }
        }
        return null;
      }

      final apk = _isAndroid
          ? assetUrl((name) => name.endsWith('-android.apk'))
          : null;
      final manifest = await _manifest(assetUrl((n) => n == 'update.json'));

      return UpdateInfo(
        latest: latest,
        url: Uri.parse(apk ?? json['html_url'] as String),
        notes: json['body'] as String?,
        schemaChange: manifest.schemaChange,
        minSupportedVersion: manifest.minSupportedVersion,
      );
    } on Object {
      return null;
    }
  }

  Future<UpdateManifest> _manifest(String? url) async {
    if (url == null) return const UpdateManifest();
    try {
      final response = await _client.get(Uri.parse(url)).timeout(timeout);
      return response.statusCode == 200
          ? UpdateManifest.parse(response.body)
          : const UpdateManifest();
    } on Object {
      return const UpdateManifest();
    }
  }
}
