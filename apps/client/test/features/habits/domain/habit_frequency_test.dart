import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/time/date_range.dart';
import 'package:nisabit/features/habits/domain/habit_frequency.dart';

void main() {
  group('HabitFrequency.periodFor', () {
    test('daily covers only the given day', () {
      final period = HabitFrequency.daily.periodFor(DateTime(2026, 3, 11));

      expect(period, DateRange(DateTime(2026, 3, 11), DateTime(2026, 3, 11)));
    });

    test('weekly spans Monday to Sunday around a midweek day', () {
      // 2026-03-11 is a Wednesday.
      final period = HabitFrequency.weekly.periodFor(DateTime(2026, 3, 11));

      expect(period, DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 15)));
    });

    test('weekly keeps Monday as the first day of its own week', () {
      final period = HabitFrequency.weekly.periodFor(DateTime(2026, 3, 9));

      expect(period.start, DateTime(2026, 3, 9));
      expect(period.end, DateTime(2026, 3, 15));
    });

    test('weekly keeps Sunday as the last day of the week that started before it', () {
      final period = HabitFrequency.weekly.periodFor(DateTime(2026, 3, 15));

      expect(period.start, DateTime(2026, 3, 9));
      expect(period.end, DateTime(2026, 3, 15));
    });

    test('weekly crosses a month boundary', () {
      // 2026-04-01 is a Wednesday, so its week starts in March.
      final period = HabitFrequency.weekly.periodFor(DateTime(2026, 4, 1));

      expect(period, DateRange(DateTime(2026, 3, 30), DateTime(2026, 4, 5)));
    });

    test('monthly spans the whole calendar month', () {
      final period = HabitFrequency.monthly.periodFor(DateTime(2026, 3, 11));

      expect(period, DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31)));
    });

    test('monthly handles a 30-day month', () {
      final period = HabitFrequency.monthly.periodFor(DateTime(2026, 4, 17));

      expect(period.end, DateTime(2026, 4, 30));
    });

    test('monthly handles February in a common year', () {
      final period = HabitFrequency.monthly.periodFor(DateTime(2026, 2, 14));

      expect(period.end, DateTime(2026, 2, 28));
    });

    test('monthly handles February in a leap year', () {
      final period = HabitFrequency.monthly.periodFor(DateTime(2028, 2, 14));

      expect(period.end, DateTime(2028, 2, 29));
    });

    test('monthly handles December without rolling into the next year', () {
      final period = HabitFrequency.monthly.periodFor(DateTime(2026, 12, 5));

      expect(period, DateRange(DateTime(2026, 12, 1), DateTime(2026, 12, 31)));
    });

    test('yearly spans January 1st to December 31st', () {
      final period = HabitFrequency.yearly.periodFor(DateTime(2026, 7, 20));

      expect(period, DateRange(DateTime(2026, 1, 1), DateTime(2026, 12, 31)));
    });
  });

  group('HabitFrequency.parse', () {
    test('accepts the canonical uppercase names', () {
      expect(HabitFrequency.parse('DAILY'), HabitFrequency.daily);
      expect(HabitFrequency.parse('WEEKLY'), HabitFrequency.weekly);
      expect(HabitFrequency.parse('MONTHLY'), HabitFrequency.monthly);
      expect(HabitFrequency.parse('YEARLY'), HabitFrequency.yearly);
    });

    test('normalizes casing and surrounding whitespace', () {
      expect(HabitFrequency.parse('  weekly '), HabitFrequency.weekly);
    });

    test('falls back to daily when the value is null or blank', () {
      expect(HabitFrequency.parse(null), HabitFrequency.daily);
      expect(HabitFrequency.parse(''), HabitFrequency.daily);
      expect(HabitFrequency.parse('   '), HabitFrequency.daily);
    });

    test('rejects an unknown value', () {
      expect(() => HabitFrequency.parse('HOURLY'), throwsArgumentError);
    });
  });

  group('HabitFrequency.supportsRepeatDays', () {
    test('is true only for daily and weekly', () {
      expect(HabitFrequency.daily.supportsRepeatDays, isTrue);
      expect(HabitFrequency.weekly.supportsRepeatDays, isTrue);
      expect(HabitFrequency.monthly.supportsRepeatDays, isFalse);
      expect(HabitFrequency.yearly.supportsRepeatDays, isFalse);
    });
  });
}
