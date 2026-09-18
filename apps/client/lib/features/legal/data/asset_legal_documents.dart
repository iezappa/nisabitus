import 'package:flutter/services.dart';

import '../domain/legal_document.dart';

/// Reads the legal documents bundled with the app, so they open offline.
///
/// The files are copies of `PRIVACY.md`, `TERMS.md` (English) and their
/// `.es.md` translations at the repository root; a test keeps them identical.
class AssetLegalDocuments {
  const AssetLegalDocuments(this._bundle);

  final AssetBundle _bundle;

  static const supportedLanguages = {'es', 'en'};
  static const fallbackLanguage = 'en';

  static String pathFor(LegalDocumentKind kind, String languageCode) {
    final language = supportedLanguages.contains(languageCode)
        ? languageCode
        : fallbackLanguage;
    return 'assets/legal/${kind.name}_$language.md';
  }

  Future<LegalDocument> load(
    LegalDocumentKind kind,
    String languageCode,
  ) async => LegalDocument.parse(
    await _bundle.loadString(pathFor(kind, languageCode), cache: false),
  );
}
