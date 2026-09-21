import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/steps/data/drift_step_repository.dart';
import 'package:nisabitus/features/steps/domain/step_log.dart';
import 'package:nisabitus/features/steps/domain/step_repository.dart';

void main() {
  late AppDatabase db;
  late StepRepository repository;
  final monday = DateTime(2026, 3, 9);
  final week = DateRange(monday, monday.add(const Duration(days: 6)));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftStepRepository(db);
  });
  tearDown(() => db.close());

  group('a day', () {
    test('has nothing written down until it does', () async {
      // Null, not zero. A day nobody recorded is not a day of no walking.
      expect(await repository.forDay(monday), isNull);
    });

    test('is written down and read back', () async {
      await repository.save(monday, 7421);

      expect((await repository.forDay(monday))?.steps, 7421);
    });

    test('is replaced rather than filed twice', () async {
      // The number grows through the day; nobody walks a day twice.
      await repository.save(monday, 3000);
      await repository.save(monday, 9500);

      expect((await repository.forDay(monday))?.steps, 9500);
      expect(await db.select(db.stepLogs).get(), hasLength(1));
    });

    test('keeps the time off the date', () async {
      await repository.save(
        monday.add(const Duration(hours: 22, minutes: 13)),
        5000,
      );

      expect((await repository.forDay(monday))?.steps, 5000);
    });

    test('can be taken back, which is not the same as zero', () async {
      await repository.save(monday, 5000);

      await repository.clear(monday);

      expect(await repository.forDay(monday), isNull);
    });

    test('refuses a count no one could walk', () async {
      expect(repository.save(monday, maxDailySteps + 1), throwsArgumentError);
      expect(repository.save(monday, -1), throwsArgumentError);
    });

    test('accepts a day of no walking, which happens', () async {
      await repository.save(monday, 0);

      expect((await repository.forDay(monday))?.steps, 0);
    });
  });

  group('the target', () {
    test('falls back to the shipped one when never set', () async {
      expect((await repository.goal()).steps, StepGoal.fallback.steps);
    });

    test('is replaced rather than piling up revisions', () async {
      await repository.saveGoal(StepGoal(steps: 10000));
      await repository.saveGoal(StepGoal(steps: 6000));

      expect((await repository.goal()).steps, 6000);
      expect(await db.select(db.stepGoals).get(), hasLength(1));
    });

    test('cannot be zero, which standing still would reach', () {
      expect(() => StepGoal(steps: 0), throwsArgumentError);
    });
  });

  group('the report', () {
    test('is empty before anything was walked', () async {
      final stats = await repository.statsFor(week);

      expect(stats.isEmpty, isTrue);
      expect(stats.average, 0);
      expect(stats.best, isNull);
    });

    test('averages over the days written down, not the window', () async {
      // Two days of 10.000 in a seven-day window is an average of 10.000,
      // not of 2.857: the five silent days are days nobody recorded, and
      // counting them as zero would punish not opening the app.
      await repository.save(monday, 10000);
      await repository.save(monday.add(const Duration(days: 1)), 10000);

      final stats = await repository.statsFor(week);

      expect(stats.days, 2);
      expect(stats.average, 10000);
      expect(stats.total, 20000);
    });

    test('counts the days that reached the target', () async {
      await repository.saveGoal(StepGoal(steps: 8000));
      await repository.save(monday, 9000);
      await repository.save(monday.add(const Duration(days: 1)), 4000);

      final stats = await repository.statsFor(week);

      expect(stats.goalDays, 1);
      expect(stats.goalPercent, 50);
    });

    test('names the best day', () async {
      await repository.save(monday, 4000);
      await repository.save(monday.add(const Duration(days: 2)), 12000);

      expect((await repository.statsFor(week)).best?.steps, 12000);
    });

    test('plots every day of the window, gaps included', () async {
      await repository.save(monday, 5000);

      final stats = await repository.statsFor(week);

      expect(stats.perDay, hasLength(7));
      expect(stats.perDay.first.value, 5000);
    });

    test('leaves out a day outside the window', () async {
      await repository.save(monday.subtract(const Duration(days: 1)), 9999);

      expect((await repository.statsFor(week)).isEmpty, isTrue);
    });
  });

  group('the target read against a day', () {
    test('caps the bar it fills at full', () {
      // The raw figure is on screen beside it for the overshoot.
      expect(StepGoal(steps: 8000).progressFor(16000), 1);
    });

    test('is reached by walking at least it', () {
      expect(StepGoal(steps: 8000).isReachedBy(8000), isTrue);
      expect(StepGoal(steps: 8000).isReachedBy(7999), isFalse);
    });
  });
}
