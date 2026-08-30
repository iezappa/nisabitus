import '../../../core/time/daily_point.dart';
import '../../../core/time/date_range.dart';
import 'nutrition.dart';

/// What the eating history says over a window.
class NutritionStats {
  const NutritionStats._({
    required this.totalCalories,
    required this.daysLogged,
    required this.goalCalories,
    required this.perDay,
  });

  /// Reads the figures off the entries of [range], in any order.
  ///
  /// Entries outside the window are dropped rather than trusted: the caller
  /// asked about a window, not about everything it happened to hand over.
  factory NutritionStats.from(
    DateRange range,
    List<FoodEntry> entries,
    NutritionGoal goal,
  ) {
    final caloriesPerDay = <DateTime, int>{};
    for (final entry in entries) {
      if (!range.contains(entry.date)) continue;

      final day = dateOnly(entry.date);
      caloriesPerDay[day] = (caloriesPerDay[day] ?? 0) + entry.macros.calories;
    }

    return NutritionStats._(
      totalCalories: caloriesPerDay.values.fold(0, (sum, v) => sum + v),
      daysLogged: caloriesPerDay.length,
      goalCalories: goal.calories,
      perDay: [
        for (final day in range.days)
          (day: day, value: (caloriesPerDay[day] ?? 0).toDouble()),
      ],
    );
  }

  final int totalCalories;

  /// Days with at least one entry. A day never logged is missing data.
  final int daysLogged;

  /// The daily target, so the chart can draw the line the user aims at.
  final int goalCalories;

  /// Energy per day, one point for every day of the window.
  final List<DailyPoint> perDay;

  /// Energy on a typical day the user actually logged.
  ///
  /// Divided by the days logged rather than by the window: a day with no
  /// record is silence, and averaging it in would report a fast that never
  /// happened.
  int get averageCalories =>
      daysLogged == 0 ? 0 : (totalCalories / daysLogged).round();

  bool get isEmpty => daysLogged == 0;
}
