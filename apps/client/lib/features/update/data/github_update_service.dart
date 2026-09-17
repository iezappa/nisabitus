import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../release_notes/domain/app_version.dart';
import '../domain/update_info.dart';

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
  }) : _current = currentVersion;

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

  @override
  Future<UpdateInfo?> check() async {
    final now = _now();
    final last = DateTime.tryParse(_prefs.getString(lastCheckKey) ?? '');
    if (last != null && now.difference(last) < throttle) return null;
    await _prefs.setString(lastCheckKey, now.toIso8601String());

    try {
      final response = await _client
          .get(
            Uri.parse(latestReleaseUrl),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = parseReleaseVersion(json['tag_name'] as String?);
      if (latest == null || !(latest > _current)) return null;

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
