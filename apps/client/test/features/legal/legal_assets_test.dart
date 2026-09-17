import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/legal/data/asset_legal_documents.dart';
import 'package:nisabitus/features/legal/domain/legal_document.dart';

/// The in-app copies of the legal documents are the published ones.
///
/// Flutter can only bundle files inside the package, so `PRIVACY.md` and
/// `TERMS.md` at the repository root are copied into `assets/legal/`. A copy
/// that drifts from the published text would show the user terms nobody
/// published, so this compares them byte for byte.
void main() {
  // `flutter test` runs from apps/client; the published files live two up.
  const root = '../..';

  const published = {
    'privacy_es.md': 'PRIVACY.md',
    'privacy_en.md': 'PRIVACY.en.md',
    'terms_es.md': 'TERMS.md',
    'terms_en.md': 'TERMS.en.md',
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

  test('falls back to Spanish for a language that is not shipped', () {
    expect(
      AssetLegalDocuments.pathFor(LegalDocumentKind.terms, 'fr'),
      'assets/legal/terms_es.md',
    );
  });
}
