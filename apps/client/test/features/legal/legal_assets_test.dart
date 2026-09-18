import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/legal/data/asset_legal_documents.dart';
import 'package:nisabitus/features/legal/domain/legal_document.dart';

/// The in-app copies of the legal documents are the published ones.
///
/// Flutter can only bundle files inside the package, so `PRIVACY.md`,
/// `TERMS.md` and their `.es.md` translations at the repository root are
/// copied into `assets/legal/`. A copy
/// that drifts from the published text would show the user terms nobody
/// published, so this compares them byte for byte.
void main() {
  // `flutter test` runs from apps/client; the published files live two up.
  const root = '../..';

  const published = {
    'privacy_en.md': 'PRIVACY.md',
    'privacy_es.md': 'PRIVACY.es.md',
    'terms_en.md': 'TERMS.md',
    'terms_es.md': 'TERMS.es.md',
  };

  for (final MapEntry(key: asset, value: source) in published.entries) {
    test('assets/legal/$asset matches $source', () {
      final bundled = File('assets/legal/$asset').readAsStringSync();
      final original = File('$root/$source').readAsStringSync();

      expect(bundled, original);
      expect(original, isNot(contains('{{')), reason: 'unfilled placeholder');
    });
  }

  test('every kind and language resolves to a bundled file', () {
    for (final kind in LegalDocumentKind.values) {
      for (final language in ['es', 'en']) {
        final path = AssetLegalDocuments.pathFor(kind, language);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('the locale picks the document in its language', () {
    expect(
      AssetLegalDocuments.pathFor(LegalDocumentKind.privacy, 'es'),
      'assets/legal/privacy_es.md',
    );
    expect(
      AssetLegalDocuments.pathFor(LegalDocumentKind.privacy, 'en'),
      'assets/legal/privacy_en.md',
    );
  });

  test('falls back to English for a language that is not shipped', () {
    expect(
      AssetLegalDocuments.pathFor(LegalDocumentKind.terms, 'fr'),
      'assets/legal/terms_en.md',
    );
  });
}
