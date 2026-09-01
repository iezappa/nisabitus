import 'package:flutter/services.dart';

import '../domain/release_notes.dart';

/// Reads the changelog that ships inside the app.
///
/// One file per language, alongside the ARB files rather than inside them: a
/// changelog only grows, and putting it in the ARBs would add a key per line
/// per release, forever, to files the rest of the interface has to live in.
class AssetReleaseNotes {
  const AssetReleaseNotes(this._bundle);

  final AssetBundle _bundle;

  /// The languages a changelog is written in. Mirrors the ARB files.
  static const supportedLanguages = {'es', 'en'};

  /// The template language, used when the device asks for one not shipped.
  static const fallbackLanguage = 'es';

  static String pathFor(String languageCode) {
    final language = supportedLanguages.contains(languageCode)
        ? languageCode
        : fallbackLanguage;

    return 'assets/release_notes/$language.json';
  }

  Future<ReleaseNotes> load(String languageCode) async =>
      ReleaseNotes.parse(await _bundle.loadString(pathFor(languageCode)));
}
