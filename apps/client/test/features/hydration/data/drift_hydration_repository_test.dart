import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/hydration/data/drift_hydration_repository.dart';
import 'package:nisabitus/features/hydration/domain/hydration.dart';
import 'package:nisabitus/features/hydration/domain/hydration_repository.dart';

void main() {
  late AppDatabase db;
  late HydrationRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftHydrationRepository(db);
  });
  tearDown(() => db.close());

  group('the target', () {
    test('starts on a default rather than on zero', () async {
      expect((await repository.goal()).isUnset, isFalse);
    });

    test('remembers what it was set to', () async {
      await repository.saveGoal(HydrationGoal(millilitres: 2500));

      expect((await repository.goal()).millilitres, 2500);
    });

    test('replaces the target rather than piling up revisions', () async {
      await repository.saveGoal(HydrationGoal(millilitres: 2500));
      await repository.saveGoal(HydrationGoal(millilitres: 3000));

      expect((await repository.goal()).millilitres, 3000);
      expect(await db.select(db.hydrationGoals).get(), hasLength(1));
    });
  });

  group('drinks', () {
    test('writes one down and reads it back on its day', () async {
      await repository.addEntry(monday, 250);

      expect((await repository.entriesFor(monday)).single.millilitres, 250);
      expect(await repository.entriesFor(tuesday), isEmpty);
    });

    test('keeps every drink of the day apart', () async {
      // Not one editable total: water is drunk in glasses, and a single
      // number typed at the end of the day is a guess.
      await repository.addEntry(monday, 250);
      await repository.addEntry(monday, 500);

      expect(await repository.entriesFor(monday), hasLength(2));
      expect((await repository.dayFor(monday)).total, 750);
    });

    test('ignores the time of day it was drunk at', () async {
      await repository.addEntry(DateTime(2026, 3, 9, 22, 15), 250);

      expect(await repository.entriesFor(monday), hasLength(1));
    });

    test('refuses a drink the domain would not accept', () async {
      expect(repository.addEntry(monday, 0), throwsArgumentError);
      expect(await repository.entriesFor(monday), isEmpty);
    });

    test('takes one back', () async {
      final entry = await repository.addEntry(monday, 250);

      await repository.deleteEntry(entry.id);

      expect(await repository.entriesFor(monday), isEmpty);
    });

    test('reads the day against the target that was set', () async {
      await repository.saveGoal(HydrationGoal(millilitres: 1000));
      await repository.addEntry(monday, 500);

      expect((await repository.dayFor(monday)).ratio, 0.5);
    });
  });

  group('the history', () {
    test('reports only the window it was asked about', () async {
      await repository.addEntry(monday, 2000);
      await repository.addEntry(tuesday, 1000);

      final stats = await repository.statsFor(DateRange(monday, monday));

      expect(stats.total, 2000);
      expect(stats.daysLogged, 1);
    });

    test('counts the days that reached the target', () async {
      await repository.saveGoal(HydrationGoal(millilitres: 2000));
      await repository.addEntry(monday, 2000);
      await repository.addEntry(tuesday, 500);

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.daysOnTarget, 1);
    });
  });
}
