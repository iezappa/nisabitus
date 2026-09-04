import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/weekday.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import '../domain/exercise_stats.dart';
import '../domain/scheduled_exercise.dart';

/// Drift-backed implementation of [ExerciseRepository].
class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Exercise>> exercises() async {
    final rows = await (_db.select(
      _db.exercises,
    )..orderBy([(e) => OrderingTerm.asc(e.name)])).get();

    return rows.map(_toExercise).toList();
  }

  @override
  Future<Exercise> createExercise(ExerciseDraft draft) async {
    final validated = Exercise(
      id: 0,
      name: draft.name,
      description: draft.description,
      muscleGroup: draft.muscleGroup,
      videoUrl: draft.videoUrl,
    );

    final id = await _db
        .into(_db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: validated.name,
            description: Value(validated.description),
            muscleGroup: Value(validated.muscleGroup),
            videoUrl: Value(validated.videoUrl),
          ),
        );

    return (await _exerciseById(id))!;
  }

  @override
  Future<Exercise> updateExercise(int id, ExerciseDraft draft) async {
    final validated = Exercise(
      id: id,
      name: draft.name,
      description: draft.description,
      muscleGroup: draft.muscleGroup,
      videoUrl: draft.videoUrl,
    );

    await (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        name: Value(validated.name),
        description: Value(validated.description),
        muscleGroup: Value(validated.muscleGroup),
        videoUrl: Value(validated.videoUrl),
      ),
    );

    return (await _exerciseById(id))!;
  }

  @override
  Future<void> deleteExercise(int id) async {
    // The cascade in the schema takes every day it was scheduled on.
    await (_db.delete(_db.exercises)..where((e) => e.id.equals(id))).go();
  }

  Future<Exercise?> _exerciseById(int id) async {
    final row = await (_db.select(
      _db.exercises,
    )..where((e) => e.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toExercise(row);
  }

  Exercise _toExercise(ExerciseRow row) => Exercise(
    id: row.id,
    name: row.name,
    description: row.description,
    muscleGroup: row.muscleGroup,
    videoUrl: row.videoUrl,
  );

  @override
  Future<ExerciseStats> statsFor(DateRange range) async {
    final rows =
        await (_db.select(_db.scheduledExercises)..where(
              (e) => e.scheduledDate.isBetweenValues(range.start, range.end),
            ))
            .get();

    return ExerciseStats.from(range, rows.map(_toScheduled).toList());
  }

  // ------------------------------------------------------ scheduled work

  @override
  Future<List<ScheduledExercise>> scheduledFor(DateTime day) async {
    final rows =
        await (_db.select(_db.scheduledExercises)
              ..where((e) => e.scheduledDate.equals(dateOnly(day)))
              ..orderBy([(e) => OrderingTerm.asc(e.id)]))
            .get();

    return rows.map(_toScheduled).toList();
  }

  @override
  Future<ScheduledExercise> schedule(
    DateTime day,
    ScheduledExerciseDraft draft, {
    ExerciseRecurrence? recurrence,
  }) async {
    final date = dateOnly(day);
    // The group id is minted before anything is written, and only when there
    // is a repetition: a single day belongs to no series, and giving it one
    // would let "stop repeating" delete a row that never repeated.
    final groupId = recurrence == null ? null : _mintGroupId(date);

    // Built first so the domain rejects an impossible target before a
    // hundred copies of it reach the database.
    final validated = ScheduledExercise(
      id: 0,
      exerciseId: draft.exerciseId,
      scheduledDate: date,
      sets: draft.sets,
      reps: draft.reps,
      weightKg: draft.weightKg,
      rpe: draft.rpe,
      comments: draft.comments,
      feedback: draft.feedback,
      recurrenceGroupId: groupId,
      repeatDays: recurrence?.days ?? const {},
      repeatForever: recurrence?.type == RecurrenceType.forever,
    );

    // The copies are worked out before the transaction so a bad recurrence
    // throws without leaving the first day behind on its own.
    final copies = recurrence?.daysAfter(date) ?? const <DateTime>[];

    return _db.transaction(() async {
      final id = await _insertScheduled(validated);
      for (final copy in copies) {
        await _insertScheduled(validated.copyWith(scheduledDate: copy));
      }

      return validated.copyWith(id: id);
    });
  }

  @override
  Future<ScheduledExercise> updateScheduled(
    int id,
    ScheduledExerciseDraft draft,
  ) async {
    final existing = await _scheduledById(id);
    if (existing == null) {
      throw StateError('Scheduled exercise $id was not found');
    }

    final validated = ScheduledExercise(
      id: id,
      exerciseId: draft.exerciseId,
      scheduledDate: existing.scheduledDate,
      sets: draft.sets,
      reps: draft.reps,
      weightKg: draft.weightKg,
      rpe: draft.rpe,
      comments: draft.comments,
      feedback: draft.feedback,
      completed: existing.completed,
      recurrenceGroupId: existing.recurrenceGroupId,
      repeatDays: existing.repeatDays,
      repeatForever: existing.repeatForever,
    );

    // This day only. The other days of the series are their own rows, and
    // reaching into them from here is how a correction becomes a rewrite.
    await (_db.update(
      _db.scheduledExercises,
    )..where((e) => e.id.equals(id))).write(
      ScheduledExercisesCompanion(
        exerciseId: Value(validated.exerciseId),
        sets: Value(validated.sets),
        reps: Value(validated.reps),
        weightKg: Value(validated.weightKg),
        rpe: Value(validated.rpe),
        comments: Value(validated.comments),
        feedback: Value(validated.feedback),
      ),
    );

    return validated;
  }

  @override
  Future<ScheduledExercise> complete(
    int id,
    ExerciseCompletion completion,
  ) async {
    final existing = await _scheduledById(id);
    if (existing == null) {
      throw StateError('Scheduled exercise $id was not found');
    }

    // What was planned stands until something is said instead: ticking a set
    // off without touching the weight means it went as written.
    final validated = ScheduledExercise(
      id: id,
      exerciseId: existing.exerciseId,
      scheduledDate: existing.scheduledDate,
      sets: existing.sets,
      reps: existing.reps,
      weightKg: completion.weightKg ?? existing.weightKg,
      rpe: completion.rpe ?? existing.rpe,
      comments: existing.comments,
      feedback: completion.feedback ?? existing.feedback,
      completed: true,
      recurrenceGroupId: existing.recurrenceGroupId,
      repeatDays: existing.repeatDays,
      repeatForever: existing.repeatForever,
    );

    await (_db.update(
      _db.scheduledExercises,
    )..where((e) => e.id.equals(id))).write(
      ScheduledExercisesCompanion(
        completed: const Value(true),
        weightKg: Value(validated.weightKg),
        rpe: Value(validated.rpe),
        feedback: Value(validated.feedback),
      ),
    );

    return validated;
  }

  @override
  Future<ScheduledExercise> reopen(int id) async {
    final existing = await _scheduledById(id);
    if (existing == null) {
      throw StateError('Scheduled exercise $id was not found');
    }

    // The feedback stays. Un-ticking something is saying it is not finished,
    // not that it never happened.
    await (_db.update(_db.scheduledExercises)..where((e) => e.id.equals(id)))
        .write(const ScheduledExercisesCompanion(completed: Value(false)));

    return existing.copyWith(completed: false);
  }

  @override
  Future<void> deleteScheduled(int id) async {
    await (_db.delete(
      _db.scheduledExercises,
    )..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<void> stopRecurrence(int id) async {
    final existing = await _scheduledById(id);
    if (existing == null) {
      throw StateError('Scheduled exercise $id was not found');
    }

    final groupId = existing.recurrenceGroupId;
    if (groupId == null || groupId.isEmpty) {
      throw StateError('Scheduled exercise $id is not part of a repetition');
    }

    await _db.transaction(() async {
      // Later, and not done. A day already trained stays on the record:
      // stopping a repetition is not undoing the training under it.
      await (_db.delete(_db.scheduledExercises)..where(
            (e) =>
                e.recurrenceGroupId.equals(groupId) &
                e.scheduledDate.isBiggerThanValue(existing.scheduledDate) &
                e.completed.equals(false),
          ))
          .go();

      // What is left is no longer waiting for more days to arrive.
      await (_db.update(
        _db.scheduledExercises,
      )..where((e) => e.recurrenceGroupId.equals(groupId))).write(
        const ScheduledExercisesCompanion(repeatForever: Value(false)),
      );
    });
  }

  Future<int> _insertScheduled(ScheduledExercise exercise) => _db
      .into(_db.scheduledExercises)
      .insert(
        ScheduledExercisesCompanion.insert(
          exerciseId: exercise.exerciseId,
          scheduledDate: exercise.scheduledDate,
          sets: exercise.sets,
          reps: exercise.reps,
          weightKg: Value(exercise.weightKg),
          rpe: Value(exercise.rpe),
          comments: Value(exercise.comments),
          feedback: Value(exercise.feedback),
          completed: Value(exercise.completed),
          recurrenceGroupId: Value(exercise.recurrenceGroupId),
          repeatDays: Value(Weekday.encode(exercise.repeatDays)),
          repeatForever: Value(exercise.repeatForever),
        ),
      );

  Future<ScheduledExercise?> _scheduledById(int id) async {
    final row = await (_db.select(
      _db.scheduledExercises,
    )..where((e) => e.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toScheduled(row);
  }

  /// A key for one repetition.
  ///
  /// The day it was created plus a counter of what already exists, which is
  /// enough to be unique here: there is one user, one device, and no sync to
  /// collide with. A UUID package for this would be a dependency earning
  /// nothing.
  String _mintGroupId(DateTime day) =>
      '${day.toIso8601String().substring(0, 10)}'
      '-${DateTime.now().microsecondsSinceEpoch}';

  ScheduledExercise _toScheduled(ScheduledExerciseRow row) => ScheduledExercise(
    id: row.id,
    exerciseId: row.exerciseId,
    scheduledDate: row.scheduledDate,
    sets: row.sets,
    reps: row.reps,
    weightKg: row.weightKg,
    rpe: row.rpe,
    comments: row.comments,
    feedback: row.feedback,
    completed: row.completed,
    recurrenceGroupId: row.recurrenceGroupId,
    repeatDays: Weekday.decode(row.repeatDays),
    repeatForever: row.repeatForever,
  );
}
