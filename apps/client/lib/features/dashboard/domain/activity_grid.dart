import '../../../core/time/date_range.dart';

/// How much was recorded on one day, as one square of the grid.
class ActivityDay {
  const ActivityDay({required this.day, required this.count});

  final DateTime day;

  /// Things written down that day, across every module.
  final int count;

  /// Which shade the square gets, 0 to 4.
  ///
  /// Fixed thresholds rather than quartiles of the busiest day, which is what
  /// GitHub does. Relative shading makes every other day dimmer the moment
  /// one day is unusually full, so the grid changes meaning without anything
  /// about those days having changed. A square here means the same thing in
  /// January as in June.
  int get level => switch (count) {
    0 => 0,
    1 || 2 => 1,
    3 || 4 || 5 => 2,
    6 || 7 || 8 || 9 => 3,
    _ => 4,
  };

  bool get isEmpty => count == 0;
}

/// Everything recorded per day over a window, laid out as weeks.
///
/// A day nobody wrote anything on is an empty square, which is the whole
/// point: the grid is a record of what was done, and a gap is a real answer.
/// It is not the same claim the progress views make — those leave silent days
/// out of their averages rather than counting them as zero — because here the
/// absence is what the reader came to see.
class ActivityGrid {
  const ActivityGrid._({required this.weeks, required this.total});

  /// Builds the grid for [range] from a count per day.
  ///
  /// [counts] is keyed by the day at midnight; a day missing from it has
  /// nothing recorded. The range is widened to whole weeks so every column
  /// holds seven squares and the rows line up under one weekday each — a
  /// ragged first column would put Monday and Thursday on the same row.
  factory ActivityGrid.from(
    DateRange range,
    Map<DateTime, int> counts, {
    required int firstWeekday,
  }) {
    final start = _startOfWeek(dateOnly(range.start), firstWeekday);
    final end = dateOnly(range.end);

    final weeks = <List<ActivityDay>>[];
    var cursor = start;
    var total = 0;

    while (!cursor.isAfter(end)) {
      final week = <ActivityDay>[];
      for (var i = 0; i < 7; i++) {
        final day = DateTime(cursor.year, cursor.month, cursor.day + i);
        // Days past the end of the window are still squares, so the last
        // column is not shorter than the others. They hold nothing, which is
        // also true: they have not happened yet.
        final count = day.isAfter(end) ? 0 : counts[day] ?? 0;
        total += count;
        week.add(ActivityDay(day: day, count: count));
      }
      weeks.add(week);
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 7);
    }

    return ActivityGrid._(weeks: weeks, total: total);
  }

  /// One list per week, each holding seven days in weekday order.
  final List<List<ActivityDay>> weeks;

  /// Everything recorded inside the window.
  final int total;

  bool get isEmpty => total == 0;

  /// How many days of the window had something on them.
  int get activeDays =>
      weeks.expand((week) => week).where((day) => !day.isEmpty).length;

  /// The longest run of consecutive days with something recorded.
  ///
  /// Counted across week boundaries, because a streak does not care what day
  /// of the week it started on. Days after today are not counted: a run
  /// cannot be broken by a day that has not arrived.
  int longestRun(DateTime today) {
    final limit = dateOnly(today);
    var best = 0;
    var current = 0;

    for (final day in weeks.expand((week) => week)) {
      if (day.day.isAfter(limit)) break;
      current = day.isEmpty ? 0 : current + 1;
      if (current > best) best = current;
    }

    return best;
  }

  static DateTime _startOfWeek(DateTime day, int firstWeekday) {
    final shift = (day.weekday - firstWeekday + 7) % 7;
    return DateTime(day.year, day.month, day.day - shift);
  }
}
