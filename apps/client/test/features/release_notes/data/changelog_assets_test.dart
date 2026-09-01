import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/release_notes/data/asset_release_notes.dart';
import 'package:nisabitus/features/release_notes/domain/release_notes.dart';

/// Guards the changelog files that ship inside the app.
///
/// They are hand-written, so a typo would otherwise reach a user as an empty
/// dialog or a crash on launch. Here it fails the suite instead.
void main() {
  ReleaseNotes read(String language) => ReleaseNotes.parse(
    File('assets/release_notes/$language.json').readAsStringSync(),
  );

  test('every language the app ships carries a changelog that parses', () {
    for (final language in AssetReleaseNotes.supportedLanguages) {
      expect(read(language).all, isNotEmpty, reason: language);
    }
  });

  test('the fallback language is one the app actually ships', () {
    expect(
      AssetReleaseNotes.supportedLanguages,
      contains(AssetReleaseNotes.fallbackLanguage),
    );
  });

  test('every language declares the same releases, on the same days', () {
    // A release translated into one language and forgotten in the other would
    // show a different history depending on the interface language. Compared
    // as text because a Dart list is only equal to itself.
    final histories = {
      for (final language in AssetReleaseNotes.supportedLanguages)
        language: [
          for (final note in read(language).all)
            '${note.version} ${note.date.toIso8601String()}',
        ].join(', '),
    };

    expect(histories.values.toSet(), hasLength(1), reason: '$histories');
  });

  test('the newest release is the version pubspec declares', () {
    // The changelog is what the app calls its own version, so the two live in
    // separate files and can drift. A release that bumped pubspec and forgot
    // to write its note would announce nothing; one that wrote the note and
    // forgot pubspec would ship under the wrong number.
    final declared = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());

    expect(declared, isNotNull, reason: 'pubspec declares no version');
    expect(
      '${read(AssetReleaseNotes.fallbackLanguage).current}',
      declared!.group(1),
    );
  });

  test('the changelog is declared as an asset, so it ships', () {
    // The files exist on disk either way, and every other test here reads
    // them from disk. Only pubspec decides whether they reach the bundle:
    // undeclared, the dialog would greet a real user with a load error.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/release_notes/'),
    );
  });

  test('every release says something in every language', () {
    for (final language in AssetReleaseNotes.supportedLanguages) {
      for (final note in read(language).all) {
        expect(
          note.highlights,
          isNotEmpty,
          reason: '$language ${note.version}',
        );
      }
    }
  });
}
