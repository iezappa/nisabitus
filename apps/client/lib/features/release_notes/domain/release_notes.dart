import 'dart:convert';

import 'app_version.dart';

/// What one release brought, in the language the file was written in.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.date,
    required this.highlights,
  });

  final AppVersion version;

  /// The day it was released, normalized to the day.
  final DateTime date;

  /// What is worth telling the user about, one line each.
  final List<String> highlights;
}

/// The whole changelog, newest release first.
///
/// This ships as an asset inside the binary rather than arriving from a
/// server: the app has no backend, so the only moment a user can learn about
/// a change is the moment they install the version that carries it.
///
/// It carries no format version either, unlike a backup file. A backup comes
/// from outside and may be older or newer than the reader; this document is
/// compiled in alongside the code that reads it and cannot disagree with it.
class ReleaseNotes {
  const ReleaseNotes._(this.all);

  /// Reads the changelog asset, refusing anything it cannot vouch for.
  ///
  /// Every rejection here is a build-time mistake — the file ships with the
  /// app — so it throws rather than degrading. A test parses both language
  /// files so a typo fails the suite instead of reaching a user.
  factory ReleaseNotes.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('The changelog is not JSON: $error', source);
    }

    if (decoded is! Map<String, dynamic>) {
      throw FormatException('The changelog is not a JSON object', source);
    }

    final releases = decoded['releases'];
    if (releases is! List || releases.isEmpty) {
      throw FormatException('The changelog declares no releases', source);
    }

    final notes = releases.map(_note).toList()
      ..sort((a, b) => b.version.compareTo(a.version));

    final seen = <AppVersion>{};
    for (final note in notes) {
      if (!seen.add(note.version)) {
        throw FormatException('Version ${note.version} appears twice', source);
      }
    }

    return ReleaseNotes._(List.unmodifiable(notes));
  }

  static ReleaseNote _note(Object? entry) {
    if (entry is! Map<String, dynamic>) {
      throw FormatException('A release is not a JSON object', '$entry');
    }

    final version = entry['version'];
    if (version is! String) {
      throw FormatException('A release carries no version', '$entry');
    }

    final date = entry['date'];
    if (date is! String) {
      throw FormatException('Release $version carries no date', '$entry');
    }

    final highlights = entry['highlights'];
    if (highlights is! List || highlights.isEmpty) {
      throw FormatException('Release $version says nothing', '$entry');
    }

    final lines = <String>[];
    for (final highlight in highlights) {
      if (highlight is! String || highlight.trim().isEmpty) {
        throw FormatException('Release $version has a blank line', '$entry');
      }
      lines.add(highlight.trim());
    }

    final day = DateTime.tryParse(date);
    if (day == null) {
      throw FormatException('Release $version has an unreadable date', date);
    }

    return ReleaseNote(
      version: AppVersion.parse(version),
      date: DateTime(day.year, day.month, day.day),
      highlights: List.unmodifiable(lines),
    );
  }

  /// Every release, newest first.
  final List<ReleaseNote> all;

  /// The version this build of the app is.
  ///
  /// The changelog is the single source of truth for it, which is why no
  /// package metadata is read: a release that forgot to write its note would
  /// otherwise announce itself with nothing to say.
  AppVersion get current => all.first.version;

  /// The releases newer than [lastSeen], newest first.
  ///
  /// A null [lastSeen] means the user has never been shown these notes, so
  /// they get the lot. A version ahead of the file — a downgrade — gets
  /// nothing rather than an error.
  List<ReleaseNote> since(AppVersion? lastSeen) => lastSeen == null
      ? all
      : all.where((note) => note.version > lastSeen).toList();
}
