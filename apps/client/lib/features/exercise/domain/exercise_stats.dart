import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'scheduled_exercise.dart';

/// What the training history says over a window.
class ExerciseStats {
  const ExerciseStats._({
    required this.sets,
    required this.reps,
    required this.volume,
    required this.daysTrained,
    required this.perDay,
  });

  /// Reads the figures off the scheduled rows of [range], in any order.
  ///
  /// Only the rows that were ticked off count. A day is written down before
  /// it is lived, so counting everything scheduled would put work on the
  /// record that nobody did — a routine planned on Sunday would read as a
  /// week already trained.
  factory ExerciseStats.from(
    DateRange range,
    List<ScheduledExercise> scheduled,
  ) {
    final done = scheduled
        .where((e) => e.completed && range.contains(e.scheduledDate))
        .toList();

    final volumePerDay = <DateTime, double>{};
    for (final row in done) {
      final day = dateOnly(row.scheduledDate);
      volumePerDay[day] = (volumePerDay[day] ?? 0) + _volumeOf(row);
    }

    return ExerciseStats._(
      sets: done.fold(0, (sum, e) => sum + e.sets),
      reps: done.fold(0, (sum, e) => sum + e.sets * e.reps),
      volume: done.fold(0, (sum, e) => sum + _volumeOf(e)),
      // Counted off the rows, not off the volume map: a day of bodyweight
      // work carries no load but is still a day trained.
      daysTrained: done.map((e) => dateOnly(e.scheduledDate)).toSet().length,
      perDay: dailySeries(range, volumePerDay),
    );
  }

  /// Sets times reps times weight. Bodyweight work carries no external load,
  /// so it contributes nothing here — which is not the same as not counting.
  static double _volumeOf(ScheduledExercise row) =>
      row.sets * row.reps * (row.weightKg ?? 0);

  final int sets;
  final int reps;

  /// Reps times weight, added up. Bodyweight work contributes nothing here.
  final double volume;

  final int daysTrained;

  /// Volume per day, one point for every day of the window.
  final List<DailyPoint> perDay;

  bool get isEmpty => sets == 0;
}
