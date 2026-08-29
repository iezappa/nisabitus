import 'habit_repository.dart';

/// What the habits progress view shows for a given window.
class HabitStats {
  const HabitStats({
    required this.completions,
    required this.habitCount,
    required this.perDay,
  });

  /// Completions recorded inside the window.
  final int completions;

  /// How many habits exist, used to estimate the rate.
  final int habitCount;

  /// Completions grouped by day, ascending. Days with none are absent.
  final List<DailyCompletionCount> perDay;

  /// A rough sense of how well the window went, as a whole percentage.
  ///
  /// This is deliberately an estimate: it compares completions against the
  /// number of habits, which are not the same unit, so it is capped at 100
  /// rather than allowed to run past a full bar.
  int get successRate {
    if (habitCount == 0) return 0;

    final rate = (completions / habitCount * 100).round();
    return rate > 100 ? 100 : rate;
  }

  bool get isEmpty => perDay.isEmpty;
}
