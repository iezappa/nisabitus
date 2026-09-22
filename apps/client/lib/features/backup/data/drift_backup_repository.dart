import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../todo/domain/board_column.dart';
import '../domain/backup_document.dart';
import '../domain/backup_repository.dart';
import '../domain/restore_report.dart';
import 'legacy_backup_ids.dart';

/// One table, in the two directions a backup needs it.
typedef _TableCodec = ({
  String name,
  Future<List<Map<String, dynamic>>> Function() dump,
  Future<List<Map<String, dynamic>>> Function() readable,
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
    // Before the tasks that sit in them, and after the projects they belong
    // to: a board is part of a project.
    _codec(_db.boardColumns, BoardColumnRow.fromJson),
    _codec(_db.todoTasks, TodoTaskRow.fromJson),
    _codec(_db.taskComments, TaskCommentRow.fromJson),
    _codec(_db.taskChecklistItems, TaskChecklistItemRow.fromJson),
    _codec(_db.nutritionGoals, NutritionGoalRow.fromJson),
    _codec(_db.foodEntries, FoodEntryRow.fromJson),
    _codec(_db.foodEntryItems, FoodEntryItemRow.fromJson),
    _codec(_db.foods, FoodRow.fromJson),
    _codec(_db.exercises, ExerciseRow.fromJson),
    _codec(_db.scheduledExercises, ScheduledExerciseRow.fromJson),
    _codec(_db.disciplines, DisciplineRow.fromJson),
    _codec(_db.stepLogs, StepLogRow.fromJson),
    _codec(_db.stepGoals, StepGoalRow.fromJson),
    _codec(_db.medications, MedicationRow.fromJson),
    _codec(_db.medicationIntakes, MedicationIntakeRow.fromJson),
    _codec(_db.hydrationGoals, HydrationGoalRow.fromJson),
    _codec(_db.waterEntries, WaterEntryRow.fromJson),
    _codec(_db.meditationSessions, MeditationSessionRow.fromJson),
    _codec(_db.vacationPeriods, VacationPeriodRow.fromJson),
    _codec(_db.audioTracks, AudioTrackRow.fromJson),
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
  Future<Map<String, List<Map<String, Object?>>>> readableTables() async => {
    for (final table in _tables) table.name: await table.readable(),
  };

  /// Dates as text a person can read in a spreadsheet.
  static const _readableSerializer = ValueSerializer.defaults(
    serializeDateTimeValuesAsString: true,
  );

  @override
  Future<RestoreReport> restore(BackupDocument original) => _db.transaction(
    () async {
      // Files written before v14 carry integer ids; they are given UUIDs,
      // references and all, before anything touches the store.
      final document = upgradeLegacyIds(original);

      // Children first on the way out, parents first on the way in:
      // foreign keys are enforced as each statement runs, not at the end.
      for (final table in _tables.reversed) {
        await table.clear();
      }

      // A file written before the board became rows carries no columns at
      // all, and its tasks name a `status` instead. Seeded rather than
      // refused: the columns are the app's own, and a backup taken before
      // they existed is not a damaged backup.
      var tables = _underTodaysNames(document.tables);
      final needsBoards = (tables['board_columns'] ?? const []).isEmpty;

      var rows = 0;
      for (final table in _tables) {
        // A table the document does not mention stays empty. The document
        // describes a whole store, so silence about a table means it held
        // nothing, not that it should be left alone.
        final placed = tables[table.name] ?? const [];
        await table.fill(placed);
        rows += placed.length;

        // Between the projects and the tasks that need somewhere to sit: a
        // board belongs to a project, so the projects have to be in place
        // before one can be given to them.
        if (needsBoards && table.name == _db.projects.actualTableName) {
          await _db.seedMissingBoards();
          tables = await _moveTasksOntoTheBoard(tables);
        }
      }

      // Counted here rather than in the document, which has no idea which
      // tables this version still has. A file older than a dropped table
      // carries rows nothing can hold, and saying so is the honest half of
      // accepting the file at all.
      final known = {for (final table in _tables) table.name};

      return RestoreReport(
        rows: rows,
        ignoredTables: {
          for (final entry in tables.entries)
            if (entry.value.isNotEmpty && !known.contains(entry.key)) entry.key,
        },
      );
    },
  );

  @override
  Future<bool> holdsUserData() async {
    for (final table in _tables) {
      final shipped = switch (table.name) {
        // What the app shipped is not what the user wrote. A renamed column
        // has had its key cleared and counts: renaming one is something the
        // user did.
        final name when name == _db.foods.actualTableName =>
          ' WHERE is_built_in = 0',
        final name when name == _db.boardColumns.actualTableName =>
          ' WHERE built_in_key IS NULL',
        _ => '',
      };
      final row = await _db
          .customSelect(
            'SELECT EXISTS(SELECT 1 FROM "${table.name}"$shipped) AS present',
          )
          .getSingle();
      if (row.read<int>('present') == 1) return true;
    }
    return false;
  }

  @override
  Future<void> eraseEverything() => _db.transaction(() async {
    for (final table in _tables.reversed) {
      await table.clear();
    }
    await _db.seedBuiltInFoods();
  });

  /// Renames the tables a file calls by a name this build has changed.
  ///
  /// `focus_sounds` became `audio_tracks` when meditation was given the same
  /// library. A file written in between holds rows under the old name, and
  /// they are the user's: dropping them and reporting the table as ignored
  /// would be accurate and useless.
  static Map<String, List<Map<String, Object?>>> _underTodaysNames(
    Map<String, List<Map<String, Object?>>> tables,
  ) {
    final renamed = tables['focus_sounds'];
    if (renamed == null) return tables;

    return {
      for (final entry in tables.entries)
        if (entry.key != 'focus_sounds') entry.key: entry.value,
      // Everything in that file was added beside the focus timer, which is
      // what the column's own default says too.
      'audio_tracks': [
        ...?tables['audio_tracks'],
        for (final row in renamed) {...row, 'usage': 'FOCUS'},
      ],
    };
  }

  /// Points the tasks of a pre-board document at a column.
  ///
  /// Those files say `status: "IN_PROGRESS"`, which was the wire name of an
  /// enum. The three names map onto the three seeded columns of the task's
  /// own project; anything else — a fork's own status, a hand-edited file —
  /// lands in that project's first column rather than being refused, which
  /// is what the store migration does with the same value and for the same
  /// reason: the task keeps everything it had and sits somewhere visible.
  Future<Map<String, List<Map<String, dynamic>>>> _moveTasksOntoTheBoard(
    Map<String, List<Map<String, dynamic>>> tables,
  ) async {
    final name = _db.todoTasks.actualTableName;
    final rows = tables[name];
    if (rows == null || rows.isEmpty) return tables;

    // Only the rows that actually name a status. A document can be stamped
    // with an older schema than its rows are shaped for, and rewriting a
    // task that already names a column would point it somewhere guessed.
    if (!rows.any((row) => row.containsKey('status'))) return tables;

    final byProject = <String, Map<String?, String>>{};
    for (final column in await _db.select(_db.boardColumns).get()) {
      (byProject[column.projectId] ??= {})[column.builtInKey] = column.id;
    }

    return {
      ...tables,
      name: [
        for (final row in rows)
          if (!row.containsKey('status'))
            row
          else
            {
              ...row,
              'columnId': _columnForStatus(
                byProject[row['projectId']?.toString()] ?? const {},
                row['status'],
              ),
            }..remove('status'),
      ],
    };
  }

  /// The column of one project's board that a pre-board `status` names.
  String? _columnForStatus(Map<String?, String> board, Object? status) {
    if (board.isEmpty) return null;

    return board[status?.toString().trim().toUpperCase()] ??
        board[BoardColumn.todoKey] ??
        board.values.first;
  }

  _TableCodec _codec<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    Insertable<D> Function(Map<String, dynamic> json) parse, {
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>>)? order,
  }) => (
    name: table.actualTableName,
    dump: () async =>
        (await _db.select(table).get()).map((row) => row.toJson()).toList(),
    readable: () async => (await _db.select(table).get())
        .map((row) => row.toJson(serializer: _readableSerializer))
        .toList(),
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
