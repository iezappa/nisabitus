import '../../exercise/domain/scheduled_exercise.dart';
import 'discipline.dart';

/// The user-editable fields of one session on one day.
class DisciplineDraft {
  const DisciplineDraft({
    required this.name,
    required this.durationMinutes,
    this.distanceKm,
    this.notes,
  });

  final String name;
  final int durationMinutes;
  final double? distanceKm;
  final String? notes;
}

/// What is recorded when a session is ticked off.
class DisciplineCompletion {
  const DisciplineCompletion({
    this.durationMinutes,
    this.distanceKm,
    this.feedback,
  });

  /// What was actually done, which is not always what was planned.
  final int? durationMinutes;
  final double? distanceKm;
  final String? feedback;
}

/// The port the discipline module talks to.
///
/// [ExerciseRecurrence] is borrowed rather than copied: repeating a swim and
/// repeating a squat is the same question, and two answers to it would drift.
abstract interface class DisciplineRepository {
  Future<List<Discipline>> forDay(DateTime day);

  Future<Discipline> schedule(
    DateTime day,
    DisciplineDraft draft, {
    ExerciseRecurrence? recurrence,
  });

  Future<Discipline> update(int id, DisciplineDraft draft);

  Future<Discipline> complete(int id, DisciplineCompletion completion);

  Future<Discipline> reopen(int id);

  Future<void> delete(int id);

  /// Stops a series from this day forward, leaving the days already
  /// practised exactly as they were.
  Future<void> stopRecurrence(int id);
}
