import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/time/date_range.dart';
import 'package:nisabit/features/streaks/data/drift_streak_repository.dart';
import 'package:nisabit/features/streaks/domain/streak.dart';
import 'package:nisabit/features/streaks/domain/streak_repository.dart';

void main() {
  late AppDatabase db;
  late StreakRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);
  final wednesday = DateTime(2026, 3, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftStreakRepository(db);
  });
  tearDown(() => db.close());

  Future<Streak> create([String name = 'Meditar']) =>
      repository.create(name, on: monday);

  group('create', () {
    test('starts both counters at zero', () async {
      final streak = await create();

      expect(streak.name, 'Meditar');
      expect(streak.count, 0);
      expect(streak.maxStreak, 0);
    });

    test('rejects a blank name', () {
      expect(() => repository.create('  ', on: monday), throwsArgumentError);
    });

    test('records no history yet', () async {
      final streak = await create();

      expect(await repository.historyFor(streak.id), isEmpty);
    });
  });

  group('increment', () {
    test('raises the count and the record together', () async {
      final streak = await create();

      final incremented = await repository.increment(streak.id, on: monday);

      expect(incremented.count, 1);
      expect(incremented.maxStreak, 1);
      expect(incremented.lastUpdated, monday);
    });

    test('appends one history point per increment', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);
      await repository.increment(streak.id, on: tuesday);

      final history = await repository.historyFor(streak.id);

      expect(history, [
        (day: monday, count: 1),
        (day: tuesday, count: 2),
      ]);
    });

    test('persists across a reload', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);

      expect((await repository.list()).single.count, 1);
    });
  });

  group('reset', () {
    test('sends the count back to zero and keeps the record', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);
      await repository.increment(streak.id, on: tuesday);

      final reset = await repository.reset(streak.id, on: wednesday);

      expect(reset.count, 0);
      expect(reset.maxStreak, 2);
      expect(reset.lastUpdated, wednesday);
    });

    test('leaves the history untouched', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);
      await repository.reset(streak.id, on: tuesday);

      expect(await repository.historyFor(streak.id), hasLength(1));
    });
  });

  group('rename and delete', () {
    test('rename replaces the name and keeps the counters', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);

      final renamed = await repository.rename(streak.id, 'Leer');

      expect(renamed.name, 'Leer');
      expect(renamed.count, 1);
    });

    test('rename rejects a blank name', () async {
      final streak = await create();

      expect(() => repository.rename(streak.id, '  '), throwsArgumentError);
    });

    test('delete removes the streak and its history', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);

      await repository.delete(streak.id);

      expect(await repository.list(), isEmpty);
      expect(await repository.historyFor(streak.id), isEmpty);
    });
  });

  group('chartSeries', () {
    test('keeps only the highest value reached on each day', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);
      await repository.increment(streak.id, on: monday);
      await repository.increment(streak.id, on: tuesday);

      final series = await repository.chartSeries(
        DateRange(monday, wednesday),
      );

      expect(series.single.name, 'Meditar');
      expect(series.single.points, [
        (day: monday, count: 2),
        (day: tuesday, count: 3),
      ]);
    });

    test('returns one series per streak', () async {
      final a = await create('Meditar');
      final b = await create('Leer');
      await repository.increment(a.id, on: monday);
      await repository.increment(b.id, on: tuesday);

      final series = await repository.chartSeries(
        DateRange(monday, wednesday),
      );

      expect(series.map((s) => s.name), ['Meditar', 'Leer']);
    });

    test('leaves out points outside the range', () async {
      final streak = await create();
      await repository.increment(streak.id, on: monday);
      await repository.increment(streak.id, on: wednesday);

      final series = await repository.chartSeries(DateRange(monday, tuesday));

      expect(series.single.points, [(day: monday, count: 1)]);
    });

    test('omits a streak with no points in the range', () async {
      final a = await create('Meditar');
      await create('Leer');
      await repository.increment(a.id, on: monday);

      final series = await repository.chartSeries(DateRange(monday, tuesday));

      expect(series.map((s) => s.name), ['Meditar']);
    });
  });
}
