import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'habit_repository.dart';

/// What the habits progress view shows for a given window.
class HabitStats {
  const HabitStats._({
    required this.completions,
    required this.habitCount,
    required this.perDay,
  });

  /// Gathers the figures the repository answered with over [range].
  ///
  /// [completionsPerDay] is the repository's own grouping, which leaves out
  /// the days that recorded nothing; the series built here carries all of
  /// them.
  factory HabitStats.from(
    DateRange range, {
    required int completions,
    required int habitCount,
    required List<DailyCompletionCount> completionsPerDay,
  }) => HabitStats._(
    completions: completions,
    habitCount: habitCount,
    perDay: dailySeries(range, {
      for (final entry in completionsPerDay) entry.day: entry.count,
    }),
  );

  /// Completions recorded inside the window.
  final int completions;

  /// How many habits exist, used to estimate the rate.
  final int habitCount;

  /// Completions per day, one point for every day of the window.
  final List<DailyPoint> perDay;

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

  /// Whether the window recorded anything at all.
  ///
  /// Read off the total rather than the series: the series always holds every
  /// day of the window, so it is never empty.
  bool get isEmpty => completions == 0;
}
