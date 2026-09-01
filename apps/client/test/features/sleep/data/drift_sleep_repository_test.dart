import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/sleep/data/drift_sleep_repository.dart';
import 'package:nisabitus/features/sleep/domain/sleep_repository.dart';

void main() {
  late AppDatabase db;
  late SleepRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);
  final wednesday = DateTime(2026, 3, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSleepRepository(db);
  });
  tearDown(() => db.close());

  group('forDay', () {
    test('is null before anything is registered', () async {
      expect(await repository.forDay(monday), isNull);
    });

    test('returns the night registered for that day', () async {
      await repository.save(monday, 7.5);

      final log = await repository.forDay(monday);

      expect(log?.hours, 7.5);
      expect(log?.date, monday);
    });

    test('ignores the time component of the day asked for', () async {
      await repository.save(monday, 7.5);

      expect(await repository.forDay(DateTime(2026, 3, 9, 22, 15)), isNotNull);
    });

    test('does not leak into a neighbouring day', () async {
      await repository.save(monday, 7.5);

      expect(await repository.forDay(tuesday), isNull);
    });
  });

  group('save', () {
    test('replaces the record of the same day instead of adding one', () async {
      await repository.save(monday, 7.5);
      await repository.save(monday, 8);

      expect((await repository.forDay(monday))?.hours, 8);
      expect(
        await repository.inRange(DateRange(monday, wednesday)),
        hasLength(1),
      );
    });

    test('rejects hours outside zero to twenty four', () {
      expect(() => repository.save(monday, 25), throwsArgumentError);
    });

    test('keeps half hours intact', () async {
      await repository.save(monday, 6.5);

      expect((await repository.forDay(monday))?.hours, 6.5);
    });
  });

  group('inRange', () {
    test('returns the nights ascending by date', () async {
      await repository.save(wednesday, 6);
      await repository.save(monday, 8);
      await repository.save(tuesday, 7);

      final logs = await repository.inRange(DateRange(monday, wednesday));

      expect(logs.map((log) => log.hours), [8, 7, 6]);
    });

    test('leaves out nights beyond the bounds', () async {
      await repository.save(monday, 8);
      await repository.save(wednesday, 6);

      final logs = await repository.inRange(DateRange(monday, tuesday));

      expect(logs.map((log) => log.hours), [8]);
    });
  });

  group('statsFor', () {
    test('is empty when the window holds nothing', () async {
      final stats = await repository.statsFor(DateRange(monday, wednesday));

      expect(stats.isEmpty, isTrue);
    });

    test('summarizes the window', () async {
      await repository.save(monday, 7);
      await repository.save(tuesday, 9);
      await repository.save(wednesday, 5);

      final stats = await repository.statsFor(DateRange(monday, wednesday));

      expect(stats.count, 3);
      expect(stats.average, 7);
      expect(stats.minHours, 5);
      expect(stats.maxHours, 9);
      expect(stats.optimalPercent, 67);
      expect(stats.latest?.date, wednesday);
    });
  });
}
