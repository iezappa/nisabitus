import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/journal/data/drift_journal_repository.dart';
import 'package:nisabitus/features/journal/domain/journal_content.dart';
import 'package:nisabitus/features/journal/domain/journal_repository.dart';

void main() {
  late AppDatabase db;
  late JournalRepository repository;

  final march = DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
  DateTime day(int d) => DateTime(2026, 3, d);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftJournalRepository(db);
  });
  tearDown(() => db.close());

  group('forDay', () {
    test('is null before anything is written', () async {
      expect(await repository.forDay(day(11)), isNull);
    });

    test('returns the entry parsed back into its six fields', () async {
      await repository.save(
        day(11),
        const JournalContent(mood: 'Tranquilo', gratitude: 'El mate'),
      );

      final entry = await repository.forDay(day(11));

      expect(entry?.content.mood, 'Tranquilo');
      expect(entry?.content.gratitude, 'El mate');
      expect(entry?.date, day(11));
    });

    test('does not leak into a neighbouring day', () async {
      await repository.save(day(11), const JournalContent(mood: 'Bien'));

      expect(await repository.forDay(day(12)), isNull);
    });
  });

  group('save', () {
    test('replaces the entry of the same day', () async {
      await repository.save(day(11), const JournalContent(mood: 'Primera'));
      await repository.save(day(11), const JournalContent(mood: 'Segunda'));

      expect((await repository.forDay(day(11)))?.content.mood, 'Segunda');
      expect((await repository.history(march)).total, 1);
    });

    test('keeps an entry readable across a reload', () async {
      await repository.save(
        day(11),
        const JournalContent(reflection: 'Línea uno\nLínea dos'),
      );

      expect(
        (await repository.forDay(day(11)))?.content.reflection,
        'Línea uno\nLínea dos',
      );
    });
  });

  group('deleteForDay', () {
    test('removes the entry', () async {
      await repository.save(day(11), const JournalContent(mood: 'Bien'));

      await repository.deleteForDay(day(11));

      expect(await repository.forDay(day(11)), isNull);
    });

    test('is harmless when there is nothing to remove', () async {
      await expectLater(repository.deleteForDay(day(11)), completes);
    });
  });

  group('history', () {
    Future<void> seed(int count) async {
      for (var i = 1; i <= count; i++) {
        await repository.save(day(i), JournalContent(mood: 'Día $i'));
      }
    }

    test('is empty when nothing was written', () async {
      final page = await repository.history(march);

      expect(page.entries, isEmpty);
      expect(page.total, 0);
      expect(page.pageCount, 0);
    });

    test('returns the newest entries first', () async {
      await seed(3);

      final page = await repository.history(march);

      expect(page.entries.map((e) => e.date), [day(3), day(2), day(1)]);
    });

    test('fills a page with five entries', () async {
      await seed(7);

      final page = await repository.history(march);

      expect(page.entries, hasLength(5));
      expect(page.total, 7);
      expect(page.pageCount, 2);
    });

    test('serves the remainder on the last page', () async {
      await seed(7);

      final page = await repository.history(march, page: 1);

      expect(page.entries, hasLength(2));
      expect(page.entries.first.date, day(2));
    });

    test('returns an empty page past the end', () async {
      await seed(3);

      expect((await repository.history(march, page: 5)).entries, isEmpty);
    });

    test('leaves out entries outside the window', () async {
      await seed(3);

      final page = await repository.history(
        DateRange(day(2), day(3)),
      );

      expect(page.entries.map((e) => e.date), [day(3), day(2)]);
      expect(page.total, 2);
    });
  });

  group('statsFor', () {
    test('reads the window as empty before anything is written', () async {
      expect((await repository.statsFor(march)).isEmpty, isTrue);
    });

    test('counts the days written inside the window', () async {
      await repository.save(day(1), const JournalContent(mood: 'Bien'));
      await repository.save(day(2), const JournalContent(mood: 'Bien'));
      await repository.save(DateTime(2026, 4, 1), const JournalContent(mood: 'Bien'));

      final stats = await repository.statsFor(march);

      expect(stats.entries, 2);
      expect(stats.longestRun, 2);
      expect(stats.perDay, hasLength(31));
    });

    test('drops an entry that was deleted', () async {
      await repository.save(day(1), const JournalContent(mood: 'Bien'));
      await repository.deleteForDay(day(1));

      expect((await repository.statsFor(march)).entries, 0);
    });
  });
}
