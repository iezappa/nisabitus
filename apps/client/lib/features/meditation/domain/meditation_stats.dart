import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'meditation.dart';

/// What the practice says over a window.
class MeditationStats {
  const MeditationStats._({
    required this.totalMinutes,
    required this.sessionCount,
    required this.daysPractised,
    required this.longestStreak,
    required this.perDay,
  });

  /// Reads the figures off the sessions of [range], in any order.
  ///
  /// Sessions outside the window are dropped rather than trusted: the caller
  /// asked about a window, not about everything it happened to hand over.
  factory MeditationStats.from(
    DateRange range,
    List<MeditationSession> sessions,
  ) {
    final perDay = <DateTime, int>{};
    var count = 0;
    for (final session in sessions) {
      if (!range.contains(session.date)) continue;

      count++;
      final day = dateOnly(session.date);
      perDay[day] = (perDay[day] ?? 0) + session.minutes;
    }

    return MeditationStats._(
      totalMinutes: perDay.values.fold(0, (sum, v) => sum + v),
      sessionCount: count,
      daysPractised: perDay.length,
      longestStreak: _longestRun(range, perDay.keys.toSet()),
      perDay: dailySeries(range, perDay),
    );
  }

  /// The longest run of consecutive days practised inside the window.
  ///
  /// Counted over the window's own days rather than over the sessions, so a
  /// gap breaks the run even when nothing was written on either side of it.
  static int _longestRun(DateRange range, Set<DateTime> days) {
    var longest = 0;
    var current = 0;
    for (final day in range.days) {
      current = days.contains(day) ? current + 1 : 0;
      if (current > longest) longest = current;
    }

    return longest;
  }

  final int totalMinutes;
  final int sessionCount;

  /// Days with at least one session. A day never written on is silence, not
  /// a day that was skipped on purpose.
  final int daysPractised;

  final int longestStreak;

  /// Minutes per day, one point for every day of the window.
  final List<DailyPoint> perDay;

  /// Minutes on a typical day that was practised.
  ///
  /// Divided by the days practised rather than by the window: averaging in
  /// the days nothing was written would report a practice falling apart when
  /// it was only unrecorded.
  int get averageMinutes =>
      daysPractised == 0 ? 0 : (totalMinutes / daysPractised).round();

  bool get isEmpty => daysPractised == 0;
}
