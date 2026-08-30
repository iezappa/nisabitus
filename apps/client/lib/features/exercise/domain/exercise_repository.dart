import '../../../core/time/date_range.dart';
import 'exercise.dart';
import 'exercise_stats.dart';

/// The user-editable fields of an exercise.
class ExerciseDraft {
  const ExerciseDraft({
    required this.name,
    this.description,
    this.muscleGroup,
  });

  final String name;
  final String? description;
  final String? muscleGroup;
}

/// The port the exercise module talks to.
abstract interface class ExerciseRepository {
  /// The catalogue, alphabetical.
  Future<List<Exercise>> exercises();

  Future<Exercise> createExercise(ExerciseDraft draft);

  Future<Exercise> updateExercise(int id, ExerciseDraft draft);

  /// Removes the exercise and every set ever logged against it.
  Future<void> deleteExercise(int id);

  /// The training done on [day], grouped by exercise.
  Future<WorkoutDay> workoutFor(DateTime day);

  /// Appends a set to the end of the day.
  Future<ExerciseSet> logSet(
    DateTime day, {
    required int exerciseId,
    required int reps,
    double? weight,
  });

  Future<ExerciseSet> updateSet(int id, {required int reps, double? weight});

  Future<void> deleteSet(int id);

  /// The figures the progress view shows for [range].
  Future<ExerciseStats> statsFor(DateRange range);
}
