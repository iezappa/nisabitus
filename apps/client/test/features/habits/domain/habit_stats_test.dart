import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/habits/domain/habit_stats.dart';

void main() {
  group('HabitStats.successRate', () {
    test('is the share of completions over the habits that exist', () {
      const stats = HabitStats(completions: 15, habitCount: 30, perDay: []);

      expect(stats.successRate, 50);
    });

    test('is zero when there are no habits, rather than dividing by zero', () {
      const stats = HabitStats(completions: 0, habitCount: 0, perDay: []);

      expect(stats.successRate, 0);
    });

    test('is capped at one hundred when completions outnumber habits', () {
      // A daily habit fulfilled across thirty days produces far more
      // completions than habits; the rate is an estimate, not a ratio that
      // may exceed a full bar.
      const stats = HabitStats(completions: 90, habitCount: 3, perDay: []);

      expect(stats.successRate, 100);
    });

    test('rounds to a whole percentage', () {
      const stats = HabitStats(completions: 1, habitCount: 3, perDay: []);

      expect(stats.successRate, 33);
    });
  });

  group('HabitStats.isEmpty', () {
    test('is true when nothing was completed in the range', () {
      const stats = HabitStats(completions: 0, habitCount: 4, perDay: []);

      expect(stats.isEmpty, isTrue);
    });

    test('is false as soon as there is one day with data', () {
      final stats = HabitStats(
        completions: 1,
        habitCount: 4,
        perDay: [(day: DateTime(2026, 3, 30), count: 1)],
      );

      expect(stats.isEmpty, isFalse);
    });
  });
}
