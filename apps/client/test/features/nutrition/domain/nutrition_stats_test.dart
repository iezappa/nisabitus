import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/time/date_range.dart';
import 'package:nisabit/features/nutrition/domain/nutrition.dart';
import 'package:nisabit/features/nutrition/domain/nutrition_stats.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 13));
  final goal = NutritionGoal(calories: 2000, protein: 120, carbs: 220, fat: 70);

  FoodEntry entry(DateTime day, int kcal) => FoodEntry(
    id: 0,
    date: day,
    name: 'Avena',
    macros: Macros(calories: kcal),
  );

  group('NutritionStats', () {
    test('reads as empty when nothing was logged', () {
      final stats = NutritionStats.from(range, const [], goal);

      expect(stats.isEmpty, isTrue);
      expect(stats.daysLogged, 0);
      expect(stats.averageCalories, 0);
    });

    test('adds up the energy of the window', () {
      final stats = NutritionStats.from(range, [
        entry(DateTime(2026, 3, 9), 600),
        entry(DateTime(2026, 3, 9), 400),
        entry(DateTime(2026, 3, 11), 1200),
      ], goal);

      expect(stats.totalCalories, 2200);
      expect(stats.daysLogged, 2);
    });

    test('averages over the days logged, not over the whole window', () {
      // A day the user never logged is missing data, not a zero-calorie day;
      // dividing by the window would report a fast that never happened.
      final stats = NutritionStats.from(range, [
        entry(DateTime(2026, 3, 9), 1000),
        entry(DateTime(2026, 3, 11), 2000),
      ], goal);

      expect(stats.averageCalories, 1500);
    });

    test('plots one point per day of the window, ascending', () {
      final stats = NutritionStats.from(range, [
        entry(DateTime(2026, 3, 11), 800),
      ], goal);

      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay.first.day, DateTime(2026, 3, 9));
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[2].value, 800);
    });

    test('ignores entries that fall outside the window', () {
      final stats = NutritionStats.from(range, [
        entry(DateTime(2026, 3, 1), 900),
        entry(DateTime(2026, 3, 10), 500),
      ], goal);

      expect(stats.totalCalories, 500);
      expect(stats.perDay, hasLength(range.dayCount));
    });

    test('carries the target so the chart can draw it', () {
      expect(NutritionStats.from(range, const [], goal).goalCalories, 2000);
    });
  });
}
