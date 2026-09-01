import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/journal/domain/journal_content.dart';

void main() {
  const full = JournalContent(
    mood: 'Tranquilo',
    energy: EnergyLevel.high,
    gratitude: 'El café de la mañana',
    focus: 'Terminar el módulo',
    reflection: 'Salió mejor de lo que esperaba',
    intention: 'Empezar temprano',
  );

  group('serialize', () {
    test('writes the six sections in order', () {
      expect(full.serialize(), '''
## Estado emocional
Tranquilo

## Energía
Alta

## Gratitud
El café de la mañana

## Foco del día
Terminar el módulo

## Reflexión
Salió mejor de lo que esperaba

## Intención para mañana
Empezar temprano'''.trim());
    });

    test('marks an empty field with a dash rather than leaving it blank', () {
      const sparse = JournalContent(reflection: 'Solo esto');

      expect(sparse.serialize(), contains('## Estado emocional\n-'));
      expect(sparse.serialize(), contains('## Reflexión\nSolo esto'));
    });

    test('leaves no energy as a dash', () {
      expect(const JournalContent().serialize(), contains('## Energía\n-'));
    });
  });

  group('parse', () {
    test('round-trips a full entry', () {
      final parsed = JournalContent.parse(full.serialize());

      expect(parsed.mood, full.mood);
      expect(parsed.energy, EnergyLevel.high);
      expect(parsed.gratitude, full.gratitude);
      expect(parsed.focus, full.focus);
      expect(parsed.reflection, full.reflection);
      expect(parsed.intention, full.intention);
    });

    test('reads a dash back as an empty field', () {
      final parsed = JournalContent.parse(const JournalContent().serialize());

      expect(parsed.mood, isEmpty);
      expect(parsed.energy, isNull);
      expect(parsed.reflection, isEmpty);
    });

    test('keeps a multi-line section together', () {
      final parsed = JournalContent.parse(
        '## Reflexión\nPrimera línea\nSegunda línea\n\n## Gratitud\n-',
      );

      expect(parsed.reflection, 'Primera línea\nSegunda línea');
    });

    test('treats content without sections as the reflection', () {
      // Backwards compatibility with entries written before the six fields.
      final parsed = JournalContent.parse('Un texto viejo, sin secciones.');

      expect(parsed.reflection, 'Un texto viejo, sin secciones.');
      expect(parsed.mood, isEmpty);
    });

    test('reads an empty string as an empty entry', () {
      expect(JournalContent.parse('').isEmpty, isTrue);
    });

    test('ignores a section it does not know', () {
      final parsed = JournalContent.parse(
        '## Inventado\nAlgo\n\n## Gratitud\nEl mate',
      );

      expect(parsed.gratitude, 'El mate');
    });
  });

  group('isEmpty', () {
    test('is true when nothing was written', () {
      expect(const JournalContent().isEmpty, isTrue);
    });

    test('is false as soon as one field carries text', () {
      expect(const JournalContent(gratitude: 'Algo').isEmpty, isFalse);
    });

    test('is false when only the energy was picked', () {
      expect(const JournalContent(energy: EnergyLevel.low).isEmpty, isFalse);
    });
  });

  group('journalPreview', () {
    test('prefers the reflection', () {
      expect(full.journalPreview, 'Salió mejor de lo que esperaba');
    });

    test('falls back to gratitude, then focus, then mood', () {
      expect(
        const JournalContent(
          mood: 'Tranquilo',
          focus: 'El módulo',
          gratitude: 'El café',
        ).journalPreview,
        'El café',
      );
      expect(
        const JournalContent(mood: 'Tranquilo', focus: 'El módulo')
            .journalPreview,
        'El módulo',
      );
      expect(const JournalContent(mood: 'Tranquilo').journalPreview, 'Tranquilo');
    });

    test('is empty when there is nothing to show', () {
      expect(const JournalContent().journalPreview, isEmpty);
    });
  });

  group('dashboardPreview', () {
    test('joins the surviving lines with a separator', () {
      const entry = JournalContent(mood: 'Tranquilo', gratitude: 'El café');

      expect(
        JournalContent.dashboardPreview(entry.serialize()),
        'Estado emocional · Tranquilo · Energía · Gratitud · El café · '
        'Foco del día · Reflexión · Intención para mañana',
      );
    });

    test('drops the dashes of the empty fields', () {
      expect(
        JournalContent.dashboardPreview(const JournalContent().serialize()),
        isNot(contains('-')),
      );
    });

    test('cuts at a hundred and twenty characters', () {
      final long = JournalContent.dashboardPreview(
        JournalContent(reflection: 'a' * 300).serialize(),
      );

      expect(long.length, 120);
    });

    test('is empty for empty content', () {
      expect(JournalContent.dashboardPreview(''), isEmpty);
    });
  });

  group('equality', () {
    test('two entries with the same fields are equal', () {
      expect(
        const JournalContent(mood: 'Bien', energy: EnergyLevel.high),
        const JournalContent(mood: 'Bien', energy: EnergyLevel.high),
      );
    });

    test('a parsed entry equals the one it came from', () {
      // The form relies on this to tell a day change from a plain rebuild.
      expect(JournalContent.parse(full.serialize()), full);
    });

    test('a difference in any field breaks equality', () {
      expect(
        const JournalContent(mood: 'Bien'),
        isNot(const JournalContent(mood: 'Mal')),
      );
      expect(
        const JournalContent(energy: EnergyLevel.low),
        isNot(const JournalContent(energy: EnergyLevel.high)),
      );
    });
  });
}
