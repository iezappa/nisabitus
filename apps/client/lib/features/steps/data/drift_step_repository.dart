import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/database/uuid.dart';
import '../../../core/time/date_range.dart';
import '../domain/step_log.dart';
import '../domain/step_repository.dart';
import '../domain/step_stats.dart';

/// Drift-backed implementation of [StepRepository].
class DriftStepRepository implements StepRepository {
  DriftStepRepository(this._db);

  final AppDatabase _db;

  @override
  Future<StepLog?> forDay(DateTime day) async {
    final row = await (_db.select(
      _db.stepLogs,
    )..where((s) => s.date.equals(dateOnly(day)))).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<StepLog> save(DateTime day, int steps) async {
    final date = dateOnly(day);
    // Built first so the domain refuses an impossible count before anything
    // is written.
    final validated = StepLog(id: newUuid(), steps: steps, date: date);

    // The unique index on the date is what makes this an update rather than
    // a second row for the same day.
    await _db
        .into(_db.stepLogs)
        .insert(
          StepLogsCompanion.insert(
            id: Value(validated.id),
            steps: validated.steps,
            date: date,
          ),
          onConflict: DoUpdate(
            // An upsert does not go through `writeTouched`, so the stamp is
            // set here or it never moves.
            (_) => StepLogsCompanion(
              steps: Value(validated.steps),
              updatedAt: Value(DateTime.now()),
            ),
            target: [_db.stepLogs.date],
          ),
        );

    return (await forDay(date))!;
  }

  @override
  Future<void> clear(DateTime day) async {
    await (_db.delete(
      _db.stepLogs,
    )..where((s) => s.date.equals(dateOnly(day)))).go();
  }

  @override
  Future<List<StepLog>> inRange(DateRange range) async {
    final rows =
        await (_db.select(_db.stepLogs)
              ..where((s) => s.date.isBetweenValues(range.start, range.end))
              ..orderBy([(s) => OrderingTerm.asc(s.date)]))
            .get();

    return [for (final row in rows) _toDomain(row)];
  }

  @override
  Future<StepGoal> goal() async {
    final row = await (_db.select(
      _db.stepGoals,
    )..where((g) => g.id.equals(singletonId))).getSingleOrNull();

    return row == null ? StepGoal.fallback : StepGoal(steps: row.steps);
  }

  @override
  Future<StepGoal> saveGoal(StepGoal goal) async {
    await _db
        .into(_db.stepGoals)
        .insertOnConflictUpdate(
          StepGoalsCompanion.insert(
            id: const Value(singletonId),
            updatedAt: Value(DateTime.now()),
            steps: Value(goal.steps),
          ),
        );

    return goal;
  }

  @override
  Future<StepStats> statsFor(DateRange range) async {
    final (logs, target) = await (inRange(range), goal()).wait;

    return StepStats.from(range, logs, target);
  }

  StepLog _toDomain(StepLogRow row) =>
      StepLog(id: row.id, steps: row.steps, date: row.date);
}
