import '../../../core/time/date_range.dart';
import 'streak.dart';

/// The value a streak had reached on a given day.
typedef StreakPoint = ({DateTime day, int count});

/// One streak's evolution over a range, ready to be drawn as a line.
class StreakSeries {
  const StreakSeries({
    required this.streakId,
    required this.name,
    required this.points,
  });

  final int streakId;
  final String name;

  /// Ascending by day, one point per day that has history.
  final List<StreakPoint> points;
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
