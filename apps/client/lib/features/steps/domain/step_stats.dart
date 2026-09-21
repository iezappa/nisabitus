import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'step_log.dart';

/// What the step history says over a window.
///
/// Every figure here is about the days that were **written down**. A day
/// nobody recorded is not a day of zero steps — it is a day nobody recorded,
/// and averaging it in as zero would punish the user for not having opened
/// the app. The chart says the same thing the other way round: it plots the
/// window so the gaps are visible, and the averages ignore them.
class StepStats {
  const StepStats._({
    required this.days,
    required this.total,
    required this.average,
    required this.best,
    required this.goalDays,
    required this.perDay,
  });

  factory StepStats.from(DateRange range, List<StepLog> logs, StepGoal goal) {
    if (logs.isEmpty) {
      return StepStats._(
        days: 0,
        total: 0,
        average: 0,
        best: null,
        goalDays: 0,
        perDay: dailySeries(range, const {}),
      );
    }

    final total = logs.fold(0, (sum, log) => sum + log.steps);
    final best = logs.reduce((a, b) => b.steps > a.steps ? b : a);

    return StepStats._(
      days: logs.length,
      total: total,
      average: total / logs.length,
      best: best,
      goalDays: logs.where((log) => goal.isReachedBy(log.steps)).length,
      perDay: dailySeries(range, {
        for (final log in logs) dateOnly(log.date): log.steps,
      }),
    );
  }

  /// How many days were written down inside the window.
  final int days;

  final int total;

  /// Steps per day **written down**, not per day in the window.
  final double average;

  /// The best day in the window, or null when there is none.
  final StepLog? best;

  /// How many of the recorded days reached the target.
  final int goalDays;

  final List<DailyPoint> perDay;

  bool get isEmpty => days == 0;

  /// The share of recorded days that reached the target, 0 to 100.
  int get goalPercent => days == 0 ? 0 : (goalDays * 100 / days).round();
}
