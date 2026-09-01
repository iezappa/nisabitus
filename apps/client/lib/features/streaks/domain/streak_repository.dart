import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'streak.dart';

/// The value a streak had reached on a given day.
typedef StreakPoint = ({DateTime day, int count});

/// One streak's evolution over a range, ready to be drawn as a line.
class StreakSeries {
  const StreakSeries._({
    required this.streakId,
    required this.name,
    required this.points,
  });

  /// Spreads the days that have history across the whole window.
  ///
  /// [highestPerDay] holds the value each recorded day ended on. Every other
  /// day of the window reads as zero, which is the honest value: a streak is
  /// a run of consecutive days, so a day nobody recorded broke it and the
  /// count started over.
  factory StreakSeries.from(
    DateRange range, {
    required int streakId,
    required String name,
    required Map<DateTime, int> highestPerDay,
  }) => StreakSeries._(
    streakId: streakId,
    name: name,
    points: dailySeries(range, highestPerDay),
  );

  final int streakId;
  final String name;

  /// Ascending by day, one point for every day of the window.
  final List<DailyPoint> points;
}

/// The port the streaks module talks to.
abstract interface class StreakRepository {
  Future<List<Streak>> list();

  Future<Streak> create(String name, {DateTime? on});

  Future<Streak> rename(int id, String name);

  Future<void> delete(int id);

  /// Adds one to the count and appends the matching history point.
  Future<Streak> increment(int id, {DateTime? on});

  /// Sends the count back to zero, keeping the record. Writes no history.
  Future<Streak> reset(int id, {DateTime? on});

  /// Every history point of one streak, ascending by day.
  Future<List<StreakPoint>> historyFor(int id);

  /// One series per streak that has history inside [range].
  ///
  /// When a streak was incremented several times on the same day, only the
  /// highest value of that day is kept: the line shows where the day ended.
  Future<List<StreakSeries>> chartSeries(DateRange range);
}
