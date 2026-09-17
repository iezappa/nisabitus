import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/legal/domain/legal_document.dart';

void main() {
  group('LegalDocument.parse', () {
    test('reads headings, bullets and paragraphs in order', () {
      final document = LegalDocument.parse('''
# Privacy

Last updated: today

## What we keep

- Nothing leaves
- No accounts
''');

      expect(document.blocks, const [
        LegalBlock.heading('Privacy', level: 1),
        LegalBlock.paragraph('Last updated: today'),
        LegalBlock.heading('What we keep', level: 2),
        LegalBlock.bullet('Nothing leaves'),
        LegalBlock.bullet('No accounts'),
      ]);
    });

    test('drops markdown emphasis and code marks, keeping the words', () {
      final document = LegalDocument.parse(
        'Stored **only on your device** in `localStorage`.',
      );

      expect(document.blocks, const [
        LegalBlock.paragraph('Stored only on your device in localStorage.'),
      ]);
    });

    test('skips HTML comments, even across lines', () {
      final document = LegalDocument.parse('''
<!--
template notes
-->
Kept
<!-- inline --> too
''');

      expect(document.blocks, const [
        LegalBlock.paragraph('Kept'),
        LegalBlock.paragraph('too'),
      ]);
    });

    test('joins consecutive lines into one paragraph', () {
      final document = LegalDocument.parse('one\ntwo\n\nthree');

      expect(document.blocks, const [
        LegalBlock.paragraph('one two'),
        LegalBlock.paragraph('three'),
      ]);
    });

    test('names the title after the first heading', () {
      expect(LegalDocument.parse('text\n# Title\n').title, 'Title');
      expect(LegalDocument.parse('no heading').title, isNull);
    });
  });
}
