import '../../../core/time/daily_point.dart';
import '../../../core/time/date_range.dart';

/// What the medication history says over a window.
///
/// Adherence is measured against the entries that are active **now**. The
/// schema does not record when an entry was activated, so a long window will
/// misread a regimen that changed inside it — a medication started yesterday
/// is counted as missed for every earlier day. Documented rather than hidden;
/// fixing it needs an `activeFrom` column.
class MedicationStats {
  const MedicationStats._({
    required this.activeCount,
    required this.completeDays,
    required this.adherencePercent,
    required this.perDay,
  });

  /// Reads the figures off the days on which something was taken.
  ///
  /// [intakeDays] holds one entry per intake of an active medication, so a
  /// day appears as many times as things were ticked on it.
  factory MedicationStats.from(
    DateRange range, {
    required int activeCount,
    required List<DateTime> intakeDays,
  }) {
    if (activeCount <= 0) {
      return MedicationStats._(
        activeCount: 0,
        completeDays: 0,
        adherencePercent: 0,
        perDay: [for (final day in range.days) (day: day, value: 0)],
      );
    }

    final takenPerDay = <DateTime, int>{};
    for (final date in intakeDays) {
      if (!range.contains(date)) continue;

      final day = dateOnly(date);
      takenPerDay[day] = (takenPerDay[day] ?? 0) + 1;
    }

    var taken = 0;
    var complete = 0;
    final perDay = <DailyPoint>[];
    for (final day in range.days) {
      // Capped: a stale intake left over from a paused entry must not read as
      // taking more than was prescribed.
      final count = (takenPerDay[day] ?? 0).clamp(0, activeCount);
      taken += count;
      if (count == activeCount) complete++;
      perDay.add((day: day, value: count / activeCount * 100));
    }

    return MedicationStats._(
      activeCount: activeCount,
      completeDays: complete,
      adherencePercent: (taken / (activeCount * range.dayCount) * 100).round(),
      perDay: perDay,
    );
  }

  /// How many entries are currently active, the denominator of a full day.
  final int activeCount;

  /// Days on which everything active was ticked.
  final int completeDays;

  /// Doses taken over doses expected, as a whole percentage.
  final int adherencePercent;

  /// Adherence per day as a percentage, one point for every day of the
  /// window. A missed day is a real zero, not a gap.
  final List<DailyPoint> perDay;

  bool get isEmpty => activeCount == 0;
}
