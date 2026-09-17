import 'dart:convert';

import '../../release_notes/domain/app_version.dart';

final _releasePattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+\d+)?$');

/// Reads a release version as tags and builds spell it: `v1.2.3`,
/// `1.2.3+4` or `1.2.3`. The build number is ignored. Anything else is null.
AppVersion? parseReleaseVersion(String? raw) {
  final match = _releasePattern.firstMatch(raw?.trim() ?? '');
  if (match == null) return null;
  return AppVersion(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
}

/// The `update.json` each release publishes (STACK-APPS-DINAMICAS.md 8.2).
class UpdateManifest {
  const UpdateManifest({this.schemaChange = false, this.minSupportedVersion});

  /// Unreadable text reads as "no schema change": a missing manifest must
  /// never block an update.
  factory UpdateManifest.parse(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic>) return const UpdateManifest();
      return UpdateManifest(
        schemaChange: json['schemaChange'] == true,
        minSupportedVersion: parseReleaseVersion(
          json['minSupportedVersion'] as String?,
        ),
      );
    } on Object {
      return const UpdateManifest();
    }
  }

  final bool schemaChange;
  final AppVersion? minSupportedVersion;
}

/// A newer version the user can move to.
class UpdateInfo {
  const UpdateInfo({
    required this.latest,
    required this.url,
    this.notes,
    this.schemaChange = false,
    this.minSupportedVersion,
  });

  final AppVersion latest;

  /// The APK, the release page, or the app itself on the web.
  final Uri url;
  final String? notes;

  /// The release changes the local schema: recommend a backup first.
  final bool schemaChange;

  /// The oldest version the migration is tested from.
  final AppVersion? minSupportedVersion;

  bool isUnsupportedFrom(AppVersion installed) =>
      minSupportedVersion != null && installed < minSupportedVersion!;
}

/// Tells whether a newer version exists.
abstract interface class UpdateService {
  /// Null when there is nothing newer, no network, or the check was
  /// throttled. Never throws: being offline is a normal case.
  Future<UpdateInfo?> check();
}
