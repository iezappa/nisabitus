import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/backup_document.dart';
import '../domain/backup_repository.dart';

/// One table, in the two directions a backup needs it.
typedef _TableCodec = ({
  String name,
  Future<List<Map<String, dynamic>>> Function() dump,
  Future<void> Function(List<Map<String, dynamic>> rows) fill,
  Future<void> Function() clear,
});

/// Drift-backed implementation of [BackupRepository].
///
/// Rows travel as Drift's own JSON, ids and all, so a restore is a copy
/// rather than a reconstruction.
class DriftBackupRepository implements BackupRepository {
  DriftBackupRepository(this._db);

  final AppDatabase _db;

  /// Every table of the store, parents before children.
  ///
  /// The order is the foreign key order: writing goes down this list, and
  /// clearing goes up it. Listed by hand rather than read off `allTables`
  /// because that order is arbitrary, and a backup that writes a child
  /// before its parent fails on the first row.
  ///
  /// A table added to the database and not added here would leave a hole in
  /// every backup; the repository test compares this list against
  /// `db.allTables` so that cannot happen quietly.
  List<_TableCodec> get _tables => [
    _codec(_db.habits, HabitRow.fromJson),
    _codec(_db.habitCompletions, HabitCompletionRow.fromJson),
    _codec(_db.streaks, StreakRow.fromJson),
    _codec(_db.streakHistoryEntries, StreakHistoryRow.fromJson),
    _codec(_db.sleepLogs, SleepLogRow.fromJson),
    _codec(_db.moodEntries, MoodEntryRow.fromJson),
    _codec(_db.pomodoroSessions, PomodoroSessionRow.fromJson),
    // Projects reference other projects, so their rows are ordered again
    // inside the table before they are written.
    _codec(_db.projects, ProjectRow.fromJson, order: _parentsFirst),
    _codec(_db.todoTasks, TodoTaskRow.fromJson),
    _codec(_db.taskComments, TaskCommentRow.fromJson),
    _codec(_db.nutritionGoals, NutritionGoalRow.fromJson),
    _codec(_db.foodEntries, FoodEntryRow.fromJson),
    _codec(_db.foods, FoodRow.fromJson),
    _codec(_db.exercises, ExerciseRow.fromJson),
    _codec(_db.exerciseSets, ExerciseSetRow.fromJson),
    _codec(_db.scheduledExercises, ScheduledExerciseRow.fromJson),
    _codec(_db.disciplines, DisciplineRow.fromJson),
    _codec(_db.medications, MedicationRow.fromJson),
    _codec(_db.medicationIntakes, MedicationIntakeRow.fromJson),
    _codec(_db.hydrationGoals, HydrationGoalRow.fromJson),
    _codec(_db.waterEntries, WaterEntryRow.fromJson),
    _codec(_db.meditationSessions, MeditationSessionRow.fromJson),
  ];

  @override
  Future<BackupDocument> export() async {
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in _tables) {
      tables[table.name] = await table.dump();
    }

    return BackupDocument(
      schemaVersion: _db.schemaVersion,
      exportedAt: DateTime.now(),
      tables: tables,
    );
  }

  @override
  Future<void> restore(BackupDocument document) => _db.transaction(() async {
    // Children first on the way out, parents first on the way in: foreign
    // keys are enforced as each statement runs, not at the end.
    for (final table in _tables.reversed) {
      await table.clear();
    }
    for (final table in _tables) {
      // A table the document does not mention stays empty. The document
      // describes a whole store, so silence about a table means it held
      // nothing, not that it should be left alone.
      await table.fill(document.tables[table.name] ?? const []);
    }
  });

  _TableCodec _codec<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    Insertable<D> Function(Map<String, dynamic> json) parse, {
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>>)? order,
  }) => (
    name: table.actualTableName,
    dump: () async =>
        (await _db.select(table).get()).map((row) => row.toJson()).toList(),
    fill: (rows) async {
      if (rows.isEmpty) return;

      await _db.batch(
        (batch) => batch.insertAll(table, (order ?? _asIs)(rows).map(parse)),
      );
    },
    clear: () => _db.delete(table).go().then((_) {}),
  );

  static List<Map<String, dynamic>> _asIs(List<Map<String, dynamic>> rows) =>
      rows;

  /// Orders rows of a self-referencing table so a parent is always written
  /// before its children.
  ///
  /// Ids alone are not enough: a project created first can be moved under
  /// one created later, and then the lower id is the child.
  ///
  /// Rows left over after no further progress is possible — a cycle, or a
  /// parent that is not in the document — are appended as they are, so the
  /// foreign key rejects them and the whole restore rolls back. Quietly
  /// dropping them would turn a corrupt file into a plausible-looking store.
  static List<Map<String, dynamic>> _parentsFirst(
    List<Map<String, dynamic>> rows,
  ) {
    final ordered = <Map<String, dynamic>>[];
    final placed = <Object?>{};
    var pending = [...rows];

    while (pending.isNotEmpty) {
      final ready = pending
          .where(
            (row) =>
                row['parentId'] == null || placed.contains(row['parentId']),
          )
          .toList();
      if (ready.isEmpty) break;

      for (final row in ready) {
        ordered.add(row);
        placed.add(row['id']);
      }
      pending = pending.where((row) => !ready.contains(row)).toList();
    }

    return [...ordered, ...pending];
  }
}
