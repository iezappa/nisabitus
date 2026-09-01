import '../../../core/time/daily_point.dart';
import '../../../core/time/date_range.dart';

/// What the medication history says over a window.
///
/// Adherence is measured day by day against what was active **on that day**,
/// not against what is active now: a medication started on Wednesday was
/// never missed on Monday, and counting it as missed would read a new
/// prescription as a fortnight of failure.
///
/// Pausing is still not dated. A paused entry drops out of the figures
/// entirely, so the days it was genuinely taken stop counting too. That is a
/// deliberate simplification: what is paused is history, and the alternative
/// is a second column recording when each pause began.
class MedicationStats {
  const MedicationStats._({
    required this.activeCount,
    required this.completeDays,
    required this.adherencePercent,
    required this.perDay,
  });

  /// Reads the figures off the days on which something was taken.
  ///
  /// [activeFrom] holds one entry per currently active medication: the day it
  /// was started, or null for one that has been active for longer than the
  /// record goes back. [intakeDays] holds one entry per intake of an active
  /// medication, so a day appears as many times as things were ticked on it.
  factory MedicationStats.from(
    DateRange range, {
    required List<DateTime?> activeFrom,
    required List<DateTime> intakeDays,
  }) {
    if (activeFrom.isEmpty) {
      return MedicationStats._(
        activeCount: 0,
        completeDays: 0,
        adherencePercent: 0,
        perDay: [for (final day in range.days) (day: day, value: 0)],
      );
    }

    final started = [
      for (final day in activeFrom) day == null ? null : dateOnly(day),
    ];

    final takenPerDay = <DateTime, int>{};
    for (final date in intakeDays) {
      if (!range.contains(date)) continue;

      final day = dateOnly(date);
      takenPerDay[day] = (takenPerDay[day] ?? 0) + 1;
    }

    var taken = 0;
    var expected = 0;
    var complete = 0;
    final perDay = <DailyPoint>[];
    for (final day in range.days) {
      final due = started
          .where((from) => from == null || !from.isAfter(day))
          .length;

      if (due == 0) {
        // Nothing had been started yet: the day is outside the regimen, not
        // a day it was skipped. It plots flat and leaves the total alone.
        perDay.add((day: day, value: 0));
        continue;
      }

      // Capped: a stale intake left over from a paused entry must not read as
      // taking more than was prescribed.
      final count = (takenPerDay[day] ?? 0).clamp(0, due);
      taken += count;
      expected += due;
      if (count == due) complete++;
      perDay.add((day: day, value: count / due * 100));
    }

    return MedicationStats._(
      activeCount: activeFrom.length,
      completeDays: complete,
      adherencePercent: expected == 0 ? 0 : (taken / expected * 100).round(),
      perDay: perDay,
    );
  }

  /// How many entries are currently active, whatever day they started on.
  final int activeCount;

  /// Days on which everything due was ticked.
  final int completeDays;

  /// Doses taken over doses expected, as a whole percentage.
  final int adherencePercent;

  /// Adherence per day as a percentage, one point for every day of the
  /// window. A missed day is a real zero, not a gap.
  final List<DailyPoint> perDay;

  bool get isEmpty => activeCount == 0;
}
