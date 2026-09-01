import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/medication/domain/medication_stats.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 12));

  group('MedicationStats', () {
    test('reads as empty when nothing is active', () {
      final stats = MedicationStats.from(
        range,
        activeCount: 0,
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
        activeCount: 2,
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
        activeCount: 2,
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
        activeCount: 2,
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
        activeCount: 1,
        intakeDays: [DateTime(2026, 3, 9), DateTime(2026, 3, 9)],
      );

      expect(stats.perDay.first.value, 100);
      expect(stats.adherencePercent, lessThanOrEqualTo(100));
    });

    test('ignores intakes outside the window', () {
      final stats = MedicationStats.from(
        range,
        activeCount: 1,
        intakeDays: [DateTime(2026, 3, 1), DateTime(2026, 3, 9)],
      );

      expect(stats.completeDays, 1);
    });
  });
}
