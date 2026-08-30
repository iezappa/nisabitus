import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import '../domain/exercise_stats.dart';

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
    );

    final id = await _db
        .into(_db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: validated.name,
            description: Value(validated.description),
            muscleGroup: Value(validated.muscleGroup),
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
    );

    await (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        name: Value(validated.name),
        description: Value(validated.description),
        muscleGroup: Value(validated.muscleGroup),
      ),
    );

    return (await _exerciseById(id))!;
  }

  @override
  Future<void> deleteExercise(int id) async {
    // The cascade in the schema takes every set logged against it.
    await (_db.delete(_db.exercises)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<WorkoutDay> workoutFor(DateTime day) async {
    final catalogue = {
      for (final exercise in await exercises()) exercise.id: exercise,
    };
    final rows =
        await (_db.select(_db.exerciseSets)
              ..where((s) => s.date.equals(dateOnly(day)))
              ..orderBy([(s) => OrderingTerm.asc(s.position)]))
            .get();

    return WorkoutDay.from(rows.map(_toSet).toList(), catalogue);
  }

  @override
  Future<ExerciseSet> logSet(
    DateTime day, {
    required int exerciseId,
    required int reps,
    double? weight,
  }) async {
    final date = dateOnly(day);
    // Position is per day, so a set always lands after whatever came before
    // it that day rather than interleaving with another date.
    final next = await _nextPosition(date);

    final validated = ExerciseSet(
      id: 0,
      exerciseId: exerciseId,
      date: date,
      reps: reps,
      weight: weight,
      position: next,
    );

    final id = await _db
        .into(_db.exerciseSets)
        .insert(
          ExerciseSetsCompanion.insert(
            exerciseId: exerciseId,
            date: date,
            position: Value(next),
            reps: validated.reps,
            weight: Value(validated.weight),
          ),
        );

    return (await _setById(id))!;
  }

  @override
  Future<ExerciseSet> updateSet(
    int id, {
    required int reps,
    double? weight,
  }) async {
    final existing = await _setById(id);
    if (existing == null) throw StateError('Exercise set $id was not found');

    final validated = ExerciseSet(
      id: id,
      exerciseId: existing.exerciseId,
      date: existing.date,
      reps: reps,
      weight: weight,
      position: existing.position,
    );

    await (_db.update(_db.exerciseSets)..where((s) => s.id.equals(id))).write(
      ExerciseSetsCompanion(
        reps: Value(validated.reps),
        weight: Value(validated.weight),
      ),
    );

    return validated;
  }

  @override
  Future<void> deleteSet(int id) async {
    await (_db.delete(_db.exerciseSets)..where((s) => s.id.equals(id))).go();
  }

  Future<int> _nextPosition(DateTime date) async {
    final highest = _db.exerciseSets.position.max();
    final query = _db.selectOnly(_db.exerciseSets)
      ..addColumns([highest])
      ..where(_db.exerciseSets.date.equals(date));

    return ((await query.getSingle()).read(highest) ?? -1) + 1;
  }

  Future<Exercise?> _exerciseById(int id) async {
    final row = await (_db.select(
      _db.exercises,
    )..where((e) => e.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toExercise(row);
  }

  Future<ExerciseSet?> _setById(int id) async {
    final row = await (_db.select(
      _db.exerciseSets,
    )..where((s) => s.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toSet(row);
  }

  Exercise _toExercise(ExerciseRow row) => Exercise(
    id: row.id,
    name: row.name,
    description: row.description,
    muscleGroup: row.muscleGroup,
  );

  @override
  Future<ExerciseStats> statsFor(DateRange range) async {
    final rows = await (_db.select(
      _db.exerciseSets,
    )..where((s) => s.date.isBetweenValues(range.start, range.end))).get();

    return ExerciseStats.from(range, rows.map(_toSet).toList());
  }

  ExerciseSet _toSet(ExerciseSetRow row) => ExerciseSet(
    id: row.id,
    exerciseId: row.exerciseId,
    date: row.date,
    reps: row.reps,
    weight: row.weight,
    position: row.position,
  );
}
