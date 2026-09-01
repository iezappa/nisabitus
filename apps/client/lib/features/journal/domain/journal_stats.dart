import '../../../core/time/daily_point.dart';
import '../../../core/time/date_range.dart';

/// What the journal history says over a window.
///
/// There is at most one entry per day, so "entries" and "days written" are
/// the same number. Coverage and the longest run are what actually differ
/// between a window written every day and one written twice.
class JournalStats {
  const JournalStats._({
    required this.entries,
    required this.coveragePercent,
    required this.longestRun,
    required this.perDay,
  });

  /// Reads the figures off the days that carry an entry, in any order.
  factory JournalStats.from(DateRange range, List<DateTime> entryDays) {
    final written = entryDays.where(range.contains).map(dateOnly).toSet();

    var longest = 0;
    var current = 0;
    final perDay = <DailyPoint>[];
    for (final day in range.days) {
      final has = written.contains(day);
      current = has ? current + 1 : 0;
      if (current > longest) longest = current;
      perDay.add((day: day, value: has ? 1 : 0));
    }

    return JournalStats._(
      entries: written.length,
      coveragePercent: (written.length / range.dayCount * 100).round(),
      longestRun: longest,
      perDay: perDay,
    );
  }

  final int entries;

  /// Share of the window's days that carry an entry.
  final int coveragePercent;

  /// The longest stretch of consecutive days written inside the window.
  final int longestRun;

  /// One per day: written or not.
  final List<DailyPoint> perDay;

  bool get isEmpty => entries == 0;
}
