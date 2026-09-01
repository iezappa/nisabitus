import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/habits/domain/habit_stats.dart';

void main() {
  final march = DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));

  HabitStats stats({
    required int completions,
    required int habitCount,
    List<({DateTime day, int count})> perDay = const [],
    DateRange? range,
  }) => HabitStats.from(
    range ?? march,
    completions: completions,
    habitCount: habitCount,
    completionsPerDay: perDay,
  );

  group('HabitStats.successRate', () {
    test('is the share of completions over the habits that exist', () {
      expect(stats(completions: 15, habitCount: 30).successRate, 50);
    });

    test('is zero when there are no habits, rather than dividing by zero', () {
      expect(stats(completions: 0, habitCount: 0).successRate, 0);
    });

    test('is capped at one hundred when completions outnumber habits', () {
      // A daily habit fulfilled across thirty days produces far more
      // completions than habits; the rate is an estimate, not a ratio that
      // may exceed a full bar.
      expect(stats(completions: 90, habitCount: 3).successRate, 100);
    });

    test('rounds to a whole percentage', () {
      expect(stats(completions: 1, habitCount: 3).successRate, 33);
    });
  });

  group('HabitStats.isEmpty', () {
    test('is true when nothing was completed in the range', () {
      expect(stats(completions: 0, habitCount: 4).isEmpty, isTrue);
    });

    test('is false as soon as there is one day with data', () {
      final withOne = stats(
        completions: 1,
        habitCount: 4,
        perDay: [(day: DateTime(2026, 3, 30), count: 1)],
      );

      expect(withOne.isEmpty, isFalse);
    });

    // The series always spans the window, so an empty window still holds
    // points. Reading emptiness off the series would never report it.
    test('is read off the total rather than off the series', () {
      expect(stats(completions: 0, habitCount: 4).perDay, isNotEmpty);
    });
  });

  group('HabitStats.perDay', () {
    test('carries one point for every day of the window', () {
      final week = stats(
        completions: 1,
        habitCount: 2,
        perDay: [(day: DateTime(2026, 3, 3), count: 1)],
        range: DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 7)),
      );

      expect(week.perDay.length, 7);
      expect(week.perDay[2].value, 1);
      expect(week.perDay[3].value, 0);
    });

    test('drops a day the repository answered outside the window', () {
      final week = stats(
        completions: 1,
        habitCount: 2,
        perDay: [
          (day: DateTime(2026, 3, 3), count: 1),
          (day: DateTime(2026, 4, 1), count: 5),
        ],
        range: DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 7)),
      );

      expect(week.perDay.length, 7);
      expect(
        week.perDay.map((point) => point.value).reduce((a, b) => a + b),
        1,
      );
    });
  });
}
