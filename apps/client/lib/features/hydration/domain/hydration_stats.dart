import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'hydration.dart';

/// What the drinking history says over a window.
class HydrationStats {
  const HydrationStats._({
    required this.total,
    required this.daysLogged,
    required this.daysOnTarget,
    required this.goalMillilitres,
    required this.perDay,
  });

  /// Reads the figures off the drinks of [range], in any order.
  ///
  /// Drinks outside the window are dropped rather than trusted: the caller
  /// asked about a window, not about everything it happened to hand over.
  factory HydrationStats.from(
    DateRange range,
    List<WaterEntry> entries,
    HydrationGoal goal,
  ) {
    final perDay = <DateTime, int>{};
    for (final entry in entries) {
      if (!range.contains(entry.date)) continue;

      final day = dateOnly(entry.date);
      perDay[day] = (perDay[day] ?? 0) + entry.millilitres;
    }

    return HydrationStats._(
      total: perDay.values.fold(0, (sum, v) => sum + v),
      daysLogged: perDay.length,
      daysOnTarget: goal.millilitres <= 0
          ? 0
          : perDay.values.where((ml) => ml >= goal.millilitres).length,
      goalMillilitres: goal.millilitres,
      perDay: dailySeries(range, perDay),
    );
  }

  final int total;

  /// Days with at least one drink. A day never logged is missing data, not a
  /// day without water.
  final int daysLogged;

  /// Days that reached the target.
  final int daysOnTarget;

  /// The daily target, so the chart can draw the line the user aims at.
  final int goalMillilitres;

  /// Millilitres per day, one point for every day of the window.
  final List<DailyPoint> perDay;

  /// What a typical logged day came to.
  ///
  /// Divided by the days logged rather than by the window: a day with no
  /// record is silence, and averaging it in would report a thirst that was
  /// never suffered.
  int get average => daysLogged == 0 ? 0 : (total / daysLogged).round();

  bool get isEmpty => daysLogged == 0;
}
