import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'exercise.dart';

/// What the training history says over a window.
class ExerciseStats {
  const ExerciseStats._({
    required this.sets,
    required this.reps,
    required this.volume,
    required this.daysTrained,
    required this.perDay,
  });

  /// Reads the figures off the sets of [range], in any order.
  factory ExerciseStats.from(DateRange range, List<ExerciseSet> sets) {
    final inRange = sets.where((s) => range.contains(s.date)).toList();

    final volumePerDay = <DateTime, double>{};
    for (final set in inRange) {
      final day = dateOnly(set.date);
      volumePerDay[day] = (volumePerDay[day] ?? 0) + set.volume;
    }

    return ExerciseStats._(
      sets: inRange.length,
      reps: inRange.fold(0, (sum, s) => sum + s.reps),
      volume: inRange.fold(0, (sum, s) => sum + s.volume),
      // Counted off the sets, not off the volume map: a day of bodyweight
      // work carries no load but is still a day trained.
      daysTrained: inRange.map((s) => dateOnly(s.date)).toSet().length,
      perDay: dailySeries(range, volumePerDay),
    );
  }

  final int sets;
  final int reps;

  /// Reps times weight, added up. Bodyweight work contributes nothing here.
  final double volume;

  final int daysTrained;

  /// Volume per day, one point for every day of the window.
  final List<DailyPoint> perDay;

  bool get isEmpty => sets == 0;
}
