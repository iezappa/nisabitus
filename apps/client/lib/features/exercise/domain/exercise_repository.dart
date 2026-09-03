import '../../../core/time/date_range.dart';
import 'exercise.dart';
import 'exercise_stats.dart';
import 'scheduled_exercise.dart';

/// The user-editable fields of an exercise.
class ExerciseDraft {
  const ExerciseDraft({
    required this.name,
    this.description,
    this.muscleGroup,
    this.videoUrl,
  });

  final String name;
  final String? description;
  final String? muscleGroup;

  /// A link showing how the movement is done. It belongs to the movement, so
  /// it is right once instead of copied into every routine that uses it.
  final String? videoUrl;
}

/// The user-editable fields of one exercise on one day.
///
/// The same draft writes the plan and, later, what happened: there is one row
/// and it holds both.
class ScheduledExerciseDraft {
  const ScheduledExerciseDraft({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weightKg,
    this.rpe,
    this.comments,
    this.feedback,
  });

  final int exerciseId;
  final int sets;
  final int reps;
  final double? weightKg;
  final int? rpe;
  final String? comments;
  final String? feedback;
}

/// What is recorded when an exercise is ticked off.
class ExerciseCompletion {
  const ExerciseCompletion({this.weightKg, this.rpe, this.feedback});

  /// What was actually lifted, which is not always what was planned.
  final double? weightKg;
  final int? rpe;
  final String? feedback;
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
    String? note,
  });

  Future<ExerciseSet> updateSet(
    int id, {
    required int reps,
    double? weight,
    String? note,
  });

  Future<void> deleteSet(int id);

  Future<ExerciseSet> updateSetNote(int id, String? note);

  /// The figures the progress view shows for [range].
  Future<ExerciseStats> statsFor(DateRange range);

  /// What is scheduled for [day], in the order it was written down.
  Future<List<ScheduledExercise>> scheduledFor(DateTime day);

  /// Writes an exercise down on [day], and on every day [recurrence] repeats
  /// it on.
  ///
  /// The copies are written now rather than worked out later. A day that has
  /// its own row can be corrected, ticked and commented on without any of it
  /// reaching the days around it.
  Future<ScheduledExercise> schedule(
    DateTime day,
    ScheduledExerciseDraft draft, {
    ExerciseRecurrence? recurrence,
  });

  /// Corrects one day. Never the series: the other days are their own rows.
  Future<ScheduledExercise> updateScheduled(
    int id,
    ScheduledExerciseDraft draft,
  );

  /// Ticks it off, recording what actually happened while doing so.
  Future<ScheduledExercise> complete(int id, ExerciseCompletion completion);

  /// Puts it back to pending, leaving what was written about it alone.
  Future<ScheduledExercise> reopen(int id);

  Future<void> deleteScheduled(int id);

  /// Stops a series from this day forward.
  ///
  /// Every later day that has not been done yet is removed; the days already
  /// lived stay exactly as they were. Stopping a repetition is not undoing
  /// the training that happened under it.
  Future<void> stopRecurrence(int id);
}
