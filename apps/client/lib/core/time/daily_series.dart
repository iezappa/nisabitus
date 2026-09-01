import 'daily_point.dart';
import 'date_range.dart';

export 'daily_point.dart';

/// Builds the dense series every progress chart is drawn from: one point for
/// every day of [range], ascending, with zero where nothing was recorded.
///
/// Density is not cosmetic. The chart places points by position, not by date,
/// so a series that skips its empty days draws a straight line across the gap
/// and reports a shape that never happened.
///
/// [valuesByDay] may be keyed by any instant; keys are normalized to their
/// calendar day, values landing on the same day are added together, and days
/// outside the window are dropped — the caller asked about a window.
List<DailyPoint> dailySeries(DateRange range, Map<DateTime, num> valuesByDay) {
  final totals = <DateTime, double>{};
  for (final entry in valuesByDay.entries) {
    final day = dateOnly(entry.key);
    if (!range.contains(day)) continue;

    totals[day] = (totals[day] ?? 0) + entry.value;
  }

  return [for (final day in range.days) (day: day, value: totals[day] ?? 0)];
}
