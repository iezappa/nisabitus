import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/medication/domain/medication_stats.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 12));

  group('MedicationStats', () {
    test('reads as empty when nothing is active', () {
      final stats = MedicationStats.from(
        range,
        activeFrom: const [],
        intakeDays: const [],
      );

      expect(stats.isEmpty, isTrue);
      expect(stats.adherencePercent, 0);
      expect(stats.completeDays, 0);
    });

    test('measures adherence against every day of the window', () {
      // Two entries over four days is eight doses expected; four were taken.
      final stats = MedicationStats.from(
        range,
        activeFrom: const [null, null],
        intakeDays: [
          DateTime(2026, 3, 9),
          DateTime(2026, 3, 9),
          DateTime(2026, 3, 10),
          DateTime(2026, 3, 12),
        ],
      );

      expect(stats.adherencePercent, 50);
    });

    test('counts a day complete only when everything active was taken', () {
      final stats = MedicationStats.from(
        range,
        activeFrom: const [null, null],
        intakeDays: [
          DateTime(2026, 3, 9),
          DateTime(2026, 3, 9),
          DateTime(2026, 3, 10),
        ],
      );

      expect(stats.completeDays, 1);
    });

    test('plots a percentage for every day, including the missed ones', () {
      final stats = MedicationStats.from(
        range,
        activeFrom: const [null, null],
        intakeDays: [DateTime(2026, 3, 10)],
      );

      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[1].value, 50);
    });

    test('never reports more than a full day', () {
      // Defensive: a stale intake against a paused entry must not push a day
      // past 100%, which would read as taking more than was prescribed.
      final stats = MedicationStats.from(
        range,
        activeFrom: const [null],
        intakeDays: [DateTime(2026, 3, 9), DateTime(2026, 3, 9)],
      );

      expect(stats.perDay.first.value, 100);
      expect(stats.adherencePercent, lessThanOrEqualTo(100));
    });

    test('ignores intakes outside the window', () {
      final stats = MedicationStats.from(
        range,
        activeFrom: const [null],
        intakeDays: [DateTime(2026, 3, 1), DateTime(2026, 3, 9)],
      );

      expect(stats.completeDays, 1);
    });

    test('never counts a day before the medication was started', () {
      // Started on the 11th: the 9th and 10th were not days it was missed,
      // they were days it had not been prescribed yet.
      final stats = MedicationStats.from(
        range,
        activeFrom: [DateTime(2026, 3, 11)],
        intakeDays: [DateTime(2026, 3, 11), DateTime(2026, 3, 12)],
      );

      expect(stats.adherencePercent, 100);
      expect(stats.completeDays, 2);
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[2].value, 100);
    });
  });
}
