import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/discipline/data/discipline_tables.dart';
import '../../features/exercise/data/exercise_tables.dart';
import '../../features/habits/data/habit_tables.dart';
import '../../features/hydration/data/hydration_tables.dart';
import '../../features/journal/data/journal_tables.dart';
import '../../features/medication/data/medication_tables.dart';
import '../../features/meditation/data/meditation_tables.dart';
import '../../features/nutrition/data/argentine_food_seed.dart';
import '../../features/nutrition/data/nutrition_tables.dart';
import '../../features/pomodoro/data/pomodoro_tables.dart';
import '../../features/sleep/data/sleep_tables.dart';
import '../../features/streaks/data/streak_tables.dart';
import '../../features/todo/data/todo_tables.dart';
import '../../features/vacation/data/vacation_tables.dart';
import 'record_columns.dart';
import 'storage_durability.dart';
import 'uuid.dart';

part 'app_database.g.dart';

/// The single local store shared by every module.
///
/// Nothing here ever leaves the device: there is no account, no sync and no
/// remote endpoint. A backup is an explicit export the user asks for.
@DriftDatabase(
  tables: [
    Habits,
    HabitCompletions,
    Streaks,
    StreakHistoryEntries,
    SleepLogs,
    MoodEntries,
    PomodoroSessions,
    Projects,
    BoardColumns,
    TodoTasks,
    TaskComments,
    TaskChecklistItems,
    NutritionGoals,
    FoodEntries,
    FoodEntryItems,
    Foods,
    Exercises,
    ScheduledExercises,
    Disciplines,
    StepLogs,
    StepGoals,
    Medications,
    MedicationIntakes,
    HydrationGoals,
    WaterEntries,
    MeditationSessions,
    VacationPeriods,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({void Function(StorageDurability)? onStorageChosen})
    : super(
        driftDatabase(
          name: storeName,
          web: DriftWebOptions(
            sqlite3Wasm: sqlite3WasmUri,
            driftWorker: driftWorkerUri,
            onResult: (result) => onStorageChosen?.call(
              durabilityOf(result.chosenImplementation),
            ),
          ),
        ),
      );

  /// The name the store is opened under: `nisabitus.sqlite` on native
  /// platforms, the browser database of the same name on the web.
  static const storeName = 'nisabitus';

  /// Where the browser build finds its database engine.
  ///
  /// On the web there is no SQLite to link against: sqlite3 is shipped as
  /// WebAssembly and driven from a worker, so both files travel in `web/` and
  /// are named here. Without this the very first query throws — every screen
  /// in the app reads from the database, so the whole app fails at once,
  /// which is exactly how it was found.
  ///
  /// Both files are pinned to the versions of `drift` and `sqlite3` in
  /// `pubspec.lock`. Bumping either package means downloading the matching
  /// pair again from their releases.
  static final sqlite3WasmUri = Uri.parse('sqlite3.wasm');
  static final driftWorkerUri = Uri.parse('drift_worker.js');

  /// Used by tests to run against a throwaway in-memory database.
  AppDatabase.forTesting(super.executor);

  /// The schema this build writes, readable without opening a store — which
  /// is exactly when recovery needs it.
  static const currentSchemaVersion = 19;

  /// The id of the only row in a single-row table, such as the daily goals.
  static const singletonId = 'singleton';

  @override
  int get schemaVersion => currentSchemaVersion;

  /// Fills the food database with what the app ships.
  ///
  /// `insertOrIgnore` against the unique lower-case name, so this can be run
  /// again on a store that already has foods in it without touching a single
  /// one. A user who wrote down their own "Milanesa" keeps theirs: the seed
  /// row is dropped, not merged over it.
  ///
  /// Also run after the user erases everything, so the store they are left
  /// with is the one a fresh install has.
  Future<void> seedBuiltInFoods() => batch(
    (b) => b.insertAll(foods, [
      for (final food in argentineFoodSeed)
        FoodsCompanion.insert(
          name: food.name,
          lowerName: food.name.toLowerCase(),
          caloriesPer100g: Value(food.calories),
          proteinPer100g: Value(food.protein),
          carbsPer100g: Value(food.carbs),
          fatPer100g: Value(food.fat),
          isBuiltIn: const Value(true),
        ),
    ], mode: InsertMode.insertOrIgnore),
  );

  /// `createAll`, safe to run over a store that is already partly there.
  ///
  /// Tables go up as `CREATE TABLE IF NOT EXISTS` already; the indices are
  /// written by hand in the table files as plain `CREATE INDEX`, and those
  /// throw on a second run. On the web that second run is real: IndexedDB
  /// persists lazily, so a reload can keep every table and index of a first
  /// launch and lose the `user_version` that marked it done. The next launch
  /// creates the store again, the first index throws, drift remembers the
  /// failed migration, and every screen fails with it.
  /// The board every project starts with.
  ///
  /// Three columns, keyed rather than named, so the words come from the
  /// translations until the user renames one — see [BoardColumns]. `DONE` is
  /// the only one that counts as finished, which is what makes a task stop
  /// being overdue and what the dashboard reads.
  static const seededBoardColumns = [
    (key: 'TODO', name: 'Pendiente', countsAsDone: false),
    (key: 'IN_PROGRESS', name: 'En curso', countsAsDone: false),
    (key: 'DONE', name: 'Hecho', countsAsDone: true),
  ];

  /// Gives one project the board the app ships.
  ///
  /// Only when that project has none: a user who deleted a column they did
  /// not want must not find it back after an update.
  Future<void> seedBoardColumnsFor(String projectId) async {
    final existing = await customSelect(
      'SELECT EXISTS('
      'SELECT 1 FROM "board_columns" WHERE "project_id" = ?) AS present',
      variables: [Variable<String>(projectId)],
    ).getSingle();
    if (existing.read<int>('present') == 1) return;

    await batch(
      (b) => b.insertAll(boardColumns, [
        for (final (index, column) in seededBoardColumns.indexed)
          BoardColumnsCompanion.insert(
            projectId: projectId,
            name: column.name,
            builtInKey: Value(column.key),
            position: index,
            countsAsDone: Value(column.countsAsDone),
          ),
      ], mode: InsertMode.insertOrIgnore),
    );
  }

  /// Gives a board to every project that has none.
  Future<void> seedMissingBoards() async {
    for (final project in await select(projects).get()) {
      await seedBoardColumnsFor(project.id);
    }
  }

  Future<void> _createAllIdempotently(Migrator m) async {
    for (final entity in allSchemaEntities) {
      if (entity is Index) {
        await _createIndexIfMissing(entity);
      } else {
        await m.create(entity);
      }
    }
  }

  /// `CREATE INDEX IF NOT EXISTS`, which drift's [Migrator.create] is not.
  Future<void> _createIndexIfMissing(Index index) => customStatement(
    index.createStatementsByDialect[SqlDialect.sqlite]!.replaceFirstMapped(
      RegExp(r'^CREATE (UNIQUE )?INDEX (?!IF NOT EXISTS)'),
      (match) => 'CREATE ${match[1] ?? ''}INDEX IF NOT EXISTS ',
    ),
  );

  /// [Migrator.addColumn], skipped when the column is already there.
  ///
  /// A migration that is interrupted leaves the store partly upgraded and
  /// `user_version` untouched — drift records the new version only once the
  /// whole callback returns — so the next launch replays every step from the
  /// beginning. SQLite has no `ADD COLUMN IF NOT EXISTS`: a second run throws
  /// `duplicate column`, drift remembers the failed migration, and the store
  /// never opens again. That is every record the user ever wrote, on a device
  /// with no account to restore it from. Asking `PRAGMA table_info` first is
  /// what makes the replay a no-op instead of a wall.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final existing = await customSelect(
      'PRAGMA table_info("${table.actualTableName}")',
    ).get();
    if (existing.any((c) => c.read<String>('name') == column.name)) return;
    await m.addColumn(table, column);
  }

  /// Which table each reference column points at, by SQL name.
  static const _references = {
    ('habit_completions', 'habit_id'): 'habits',
    ('streak_history_entries', 'streak_id'): 'streaks',
    ('projects', 'parent_id'): 'projects',
    ('todo_tasks', 'project_id'): 'projects',
    ('task_comments', 'task_id'): 'todo_tasks',
    ('scheduled_exercises', 'exercise_id'): 'exercises',
    ('medication_intakes', 'medication_id'): 'medications',
  };

  /// Where a row's first `updatedAt` comes from, when it has a better answer
  /// than the moment of the migration.
  static const _lastWrittenColumn = {
    'habits': 'created_at',
    'task_comments': 'created_at',
    'streaks': 'last_updated',
  };

  static const _singletonTables = {'nutrition_goals', 'hydration_goals'};

  /// The v14 step: integer ids become UUIDs, references follow them.
  ///
  /// SQLite cannot make a UUID, so the ids are drawn in Dart first and
  /// written to a scratch map of `(table, old id) -> new id`. Each table is
  /// then rebuilt with [Migrator.alterTable], reading its own new id and every
  /// reference's new id out of that map — so a child ends up pointing at the
  /// same parent it pointed at before, whatever order the tables go in.
  ///
  /// Only tables whose id is still an integer are converted. A table an
  /// earlier step of this same upgrade created is already in the v14 shape,
  /// and empty.
  ///
  /// A reference to a parent that no longer exists cannot be translated, and
  /// with foreign keys enforced it could never have been shown. Those rows
  /// are removed first rather than failing the whole upgrade on them.
  Future<void> _giveEveryRecordAUuid(Migrator m) async {
    final legacy = <TableInfo<Table, dynamic>>[];
    for (final table in allTables) {
      final columns = await customSelect(
        'PRAGMA table_info("${table.actualTableName}")',
      ).get();
      final id = columns.where((c) => c.read<String>('name') == 'id');
      if (id.isNotEmpty &&
          id.single.read<String>('type').toUpperCase() == 'INTEGER') {
        legacy.add(table);
      }
    }
    if (legacy.isEmpty) return;

    final names = {for (final table in legacy) table.actualTableName};

    // A single-row table that holds two rows would map both to the same
    // `singleton` id and fail the upgrade on a duplicate primary key. Nothing
    // before v14 enforced the single row, so a repository bug, a restored
    // backup or a half-finished write could leave one — a difference the user
    // never sees and did not cause, and it must not cost them the store.
    //
    // The highest id wins. With an autoincrementing id that is the row
    // written last, so it is the goal the app was already reading and the one
    // the user set most recently. There is no `updatedAt` to ask before v14;
    // this is the closest thing the old schema has to one.
    for (final name in names.where(_singletonTables.contains)) {
      await customUpdate(
        'DELETE FROM "$name" WHERE id < (SELECT MAX(id) FROM "$name")',
        updateKind: UpdateKind.delete,
      );
    }

    // Orphans first, until a pass removes nothing: deleting a project whose
    // parent is gone orphans its own children in turn.
    var removed = true;
    while (removed) {
      removed = false;
      for (final MapEntry(key: (child, column), value: parent)
          in _references.entries) {
        if (!names.contains(child) || !names.contains(parent)) continue;
        final gone = await customUpdate(
          'DELETE FROM "$child" WHERE "$column" IS NOT NULL '
          'AND "$column" NOT IN (SELECT id FROM "$parent")',
          updateKind: UpdateKind.delete,
        );
        removed = removed || gone > 0;
      }
    }

    await customStatement(
      'CREATE TEMP TABLE uuid_id_map (tbl TEXT NOT NULL, old_id INTEGER NOT '
      'NULL, new_id TEXT NOT NULL, PRIMARY KEY (tbl, old_id))',
    );
    for (final name in names) {
      final ids = await customSelect('SELECT id FROM "$name"').get();
      for (final row in ids) {
        await customStatement(
          'INSERT INTO uuid_id_map (tbl, old_id, new_id) VALUES (?, ?, ?)',
          [
            name,
            row.read<int>('id'),
            _singletonTables.contains(name) ? singletonId : newUuid(),
          ],
        );
      }
    }

    final now = DateTime.now();
    Expression<String> mapped(String table, String column, String target) =>
        CustomExpression<String>(
          '(SELECT new_id FROM uuid_id_map WHERE tbl = \'$target\' '
          'AND old_id = "$table"."$column")',
        );

    for (final table in legacy) {
      final name = table.actualTableName;
      final byName = table.columnsByName;
      final lastWritten = _lastWrittenColumn[name];

      // Every column of today's definition that the old table does not have.
      //
      // `alterTable` builds the new table from the definition in the code,
      // which is today's and not this version's: a column added by any later
      // step would be selected out of a table that has never had it, and the
      // upgrade would die on a store older than that step. Naming them as new
      // columns is what keeps this step readable by the versions that come
      // after it — and something has to be put in the ones that cannot be
      // null, which a later step then fills in properly.
      final present = {
        for (final column in await customSelect(
          'PRAGMA table_info("$name")',
        ).get())
          column.read<String>('name'),
      };
      final added = [
        for (final column in table.$columns)
          if (!present.contains(column.name)) column,
      ];

      await m.alterTable(
        TableMigration(
          table,
          newColumns: [byName['updated_at']!, ...added],
          columnTransformer: {
            for (final column in added)
              if (!column.$nullable && column.defaultValue == null)
                column: _blankFor(column),
            byName['id']!: mapped(name, 'id', name),
            byName['updated_at']!: lastWritten == null
                ? Variable<DateTime>(now)
                : CustomExpression<DateTime>('"$name"."$lastWritten"'),
            for (final MapEntry(key: (child, column), value: parent)
                in _references.entries)
              if (child == name) byName[column]!: mapped(name, column, parent),
          },
        ),
      );
    }

    await customStatement('DROP TABLE uuid_id_map');
  }

  /// A stand-in for a column that cannot be null and has no default.
  ///
  /// Only ever written by [_giveEveryRecordAUuid], and only into a column a
  /// later step of the same upgrade is about to fill: foreign keys are off
  /// while migrations run, so a reference that points nowhere for three
  /// statements costs nothing and a `NOT NULL` that is left empty costs the
  /// whole upgrade.
  Expression<Object> _blankFor(GeneratedColumn<Object> column) =>
      switch (column) {
        GeneratedColumn<int>() => const Constant<int>(0),
        GeneratedColumn<double>() => const Constant<double>(0),
        GeneratedColumn<bool>() => const Constant<bool>(false),
        _ => const Constant<String>(''),
      };

  /// Replaces `todo_tasks.status` with a reference to a row of
  /// [BoardColumns], one board per project (v15).
  ///
  /// The status was the wire name of an enum, so the board could not be
  /// rearranged without a release. Every project gets the three seeded
  /// columns and every task is pointed at its own project's copy of the one
  /// its status named. Nothing moves on screen; the board just stops being a
  /// decision the code had made.
  ///
  /// A status the enum never had — nothing writes one, but a hand-edited
  /// store or a backup from a fork could carry one — lands in that project's
  /// first column rather than stopping the upgrade. It loses nothing: the
  /// task keeps every field it had and sits where the user can see it.
  Future<void> _rebuildBoardAsColumns(Migrator m) async {
    await m.createTable(boardColumns);
    await _createIndexIdempotently(boardColumnOrder);
    await seedMissingBoards();

    // A store that came through v14 in this same upgrade has no `status` to
    // read: that step rebuilds the table from today's definition, and today's
    // has no such column. `completed_at` survives it, and it answers the half
    // of the question that matters — a finished task goes to the column that
    // finishes work, everything else to the first one. The distinction
    // between "pending" and "in progress" is what is lost, on stores older
    // than v14 only, and it is a distinction the user can see and put back.
    //
    // A store that was already at v14 — which is every released one — still
    // has `status`, and maps exactly.
    final hasStatus = await _hasColumn('todo_tasks', 'status');

    // Nothing to move when the table is already shaped for this version — a
    // store built by `onCreate`, or one where this ran and lost the version
    // that marked it done.
    if (!hasStatus && await _hasColumn('todo_tasks', 'column_id')) {
      final placed = await customSelect(
        'SELECT EXISTS(SELECT 1 FROM "todo_tasks" '
        'WHERE "column_id" != \'\') AS present',
      ).getSingle();
      if (placed.read<int>('present') == 1) return;
    }

    // Per project, because each has its own board: a single key-to-id map
    // would send a task to whichever project's column was read last.
    final byProject = <String, Map<String?, String>>{};
    for (final row in await select(boardColumns).get()) {
      (byProject[row.projectId] ??= {})[row.builtInKey] = row.id;
    }

    final tasks = [
      for (final row in await customSelect(
        'SELECT "id", "project_id", '
        '${hasStatus ? '"status"' : 'NULL AS "status"'}, '
        '"completed_at" FROM "todo_tasks"',
      ).get())
        (
          id: row.read<String>('id'),
          projectId: row.read<String>('project_id'),
          status:
              row.read<String?>('status') ??
              (row.data['completed_at'] == null ? 'TODO' : 'DONE'),
        ),
    ];

    // `status` is dropped and `column_id` added in one rebuild: SQLite can
    // drop a column, but the table has to come back anyway to carry the new
    // foreign key, which `ALTER TABLE` cannot add. Skipped when v14 already
    // left the table in today's shape — then only the second pass below is
    // needed, to fill the placeholder it wrote.
    //
    // `legacy_alter_table` for the rename, which is the documented recipe:
    // modern SQLite rewrites every foreign key that names the table being
    // renamed, so without it `task_comments` would come out of the upgrade
    // pointing at a scratch table this method drops two statements later.
    if (hasStatus) {
      await customStatement('PRAGMA legacy_alter_table = ON');
      await customStatement(
        'ALTER TABLE "todo_tasks" RENAME TO "todo_tasks_pre_board"',
      );
      await customStatement('PRAGMA legacy_alter_table = OFF');
      await customStatement('DROP INDEX IF EXISTS "task_project_lookup"');
      await m.createTable(todoTasks);
      await _createIndexIdempotently(taskProjectLookup);
      await customStatement(
        'INSERT INTO "todo_tasks" '
        '("id", "updated_at", "title", "description", "category", '
        '"start_date", "due_date", "priority", "column_id", "project_id", '
        '"completed_at") '
        'SELECT "id", "updated_at", "title", "description", "category", '
        '"start_date", "due_date", "priority", \'\', "project_id", '
        '"completed_at" FROM "todo_tasks_pre_board"',
      );
      await customStatement('DROP TABLE "todo_tasks_pre_board"');
    }

    // Outside the branch above: the index was dropped before v14 ran
    // whether or not the table needed rebuilding here, so it goes back
    // either way.
    await _createIndexIdempotently(taskProjectLookup);

    // Filled in a second pass, with foreign keys still off: the column each
    // task belongs in is a fact about its project, and the insert above can
    // only carry one value for the whole table.
    for (final task in tasks) {
      final board = byProject[task.projectId] ?? const {};
      if (board.isEmpty) continue;
      final column =
          board[task.status.trim().toUpperCase()] ??
          board['TODO'] ??
          board.values.first;
      await customStatement(
        'UPDATE "todo_tasks" SET "column_id" = ? WHERE "id" = ?',
        [column, task.id],
      );
    }
  }

  /// Whether a table still has a column by that name.
  Future<bool> _hasColumn(String table, String column) async {
    for (final row in await customSelect('PRAGMA table_info("$table")').get()) {
      if (row.read<String>('name') == column) return true;
    }
    return false;
  }

  /// `CREATE INDEX IF NOT EXISTS`, for the reason given on
  /// [_createAllIdempotently].
  Future<void> _createIndexIdempotently(Index index) => customStatement(
    index.createStatementsByDialect[SqlDialect.sqlite]!.replaceFirstMapped(
      RegExp(r'^CREATE (UNIQUE )?INDEX (?!IF NOT EXISTS)'),
      (match) => 'CREATE ${match[1] ?? ''}INDEX IF NOT EXISTS ',
    ),
  );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await _createAllIdempotently(m);
      // A fresh install gets the catalogue too. Without this the food
      // database only exists for people who upgraded into it, which is the
      // sort of difference nobody finds until a new install looks broken.
      await seedBuiltInFoods();
    },
    onUpgrade: (m, from, to) async {
      // One transaction around every step, so an upgrade is all or nothing.
      //
      // drift writes `user_version` only after this callback returns, so a
      // process killed halfway leaves a store that says it is still on the
      // old version while some of the new shape is already on disk. Without a
      // transaction the next launch replays the steps over that half-done
      // work; with one, the crash rolls the store back to exactly the version
      // it still claims to be. SQLite makes DDL transactional, so the
      // `CREATE TABLE`s and `ALTER TABLE`s roll back with the rest.
      //
      // The steps are written to be idempotent anyway — `IF NOT EXISTS`,
      // `_addColumnIfMissing` — because a store already half-upgraded by a
      // build that lacked this transaction still has to be able to open.
      await transaction(() async {
        // v2 added the nutrition and exercise tables. Everything already
        // stored is untouched: this only creates what did not exist.
        //
        // The indices go up by hand: `createTable` writes the table and
        // nothing else, so a database that arrived here through a migration
        // would run without them. `intake_by_day` is unique, so its absence
        // would not merely slow a query down — it would let the same thing be
        // ticked twice on one day.
        if (from < 2) {
          await m.createTable(nutritionGoals);
          await m.createTable(foodEntries);
          await m.createTable(exercises);
          await _createIndexIfMissing(foodEntryByDay);
        }
        // v3 added medication and supplement tracking.
        if (from < 3) {
          await m.createTable(medications);
          await m.createTable(medicationIntakes);
          await _createIndexIfMissing(intakeByDay);
        }
        // v4 records when a task was finished. Existing tasks keep a null
        // date: their status is known, the moment is not, and inventing one
        // would put fictional work on the chart.
        if (from < 4) {
          await _addColumnIfMissing(m, todoTasks, todoTasks.completedAt);
        }
        // v5 records the day a medication started counting. Existing entries
        // keep a null start: they were prescribed before the app asked, and
        // stamping them with today would read as a regimen begun this morning.
        //
        // Only for a database that already had the table. `createTable` builds
        // it from today's definition, this column included, so a database
        // arriving from before v3 got it above and adding it again would fail
        // on a duplicate column.
        if (from >= 3 && from < 5) {
          await _addColumnIfMissing(m, medications, medications.activeFrom);
        }
        // v6 gave eating a shape: which meal an entry belonged to, and a
        // catalogue of foods so the same breakfast is picked rather than typed
        // again.
        //
        // Existing entries keep a null meal. They were written before the app
        // asked, and calling them all lunch would put food on the record at an
        // hour nobody ate it.
        //
        // Same split as v5: `createTable` builds `food_entries` from today's
        // definition, `meal` included, so only a database that already had the
        // table needs the column added.
        if (from >= 2 && from < 6) {
          await _addColumnIfMissing(m, foodEntries, foodEntries.meal);
        }
        // v9 added a reference video to the movement, which is null for
        // everything already stored — honest, because nobody was asked, so
        // nobody answered.
        //
        // Same split as v5 and v6: `createTable` builds `exercises` from
        // today's definition, this column included, so only a database that
        // already had the table needs it added.
        //
        // v9 also added a note to `exercise_sets`. That table is gone as of
        // v12, so the column it wanted is not added here any more: adding a
        // column to a table this same migration is about to drop is work
        // nobody would ever read.
        if (from >= 2 && from < 9) {
          await _addColumnIfMissing(m, exercises, exercises.videoUrl);
        }
        // v11 adds what is practised for a time rather than counted in sets:
        // swimming, running, cycling. Its own table, because a swim has a
        // duration and a distance and no sets — one table for both shapes
        // would be one table with half its columns null on every row.
        if (from < 11) {
          await m.createTable(disciplines);
          await _createIndexIfMissing(disciplineByDay);
          await _createIndexIfMissing(disciplineByGroup);
        }
        // v10 replaces v9's routine tables with one row per exercise per day.
        //
        // v9 kept the plan and the record apart and compared them when reading.
        // It works, and it is the wrong shape for this: a day that has its own
        // row cannot have its past rewritten by a correction made tomorrow, and
        // it is what habits in this same app already do. The routine tables go
        // rather than linger — a table nothing reads is a question every later
        // reader has to answer.
        //
        // Only v9 ever had them, and only on the machine they were written on.
        if (from >= 9 && from < 10) {
          await m.deleteTable('routine_exercises');
          await m.deleteTable('routines');
        }
        if (from < 10) {
          await m.createTable(scheduledExercises);
          await _createIndexIfMissing(scheduledExerciseByDay);
          await _createIndexIfMissing(scheduledExerciseByGroup);
        }
        // v8 records meditation. Nothing existing changes, for the same
        // reason as v7: an app that never had a practice log has no sittings
        // to migrate.
        if (from < 8) {
          await m.createTable(meditationSessions);
          await _createIndexIfMissing(meditationByDay);
        }
        // v7 records water. Nothing existing changes: an app that never had a
        // hydration log has no water to migrate, and a day with no drinks
        // stays a day nobody wrote anything down on.
        if (from < 7) {
          await m.createTable(hydrationGoals);
          await m.createTable(waterEntries);
          await _createIndexIfMissing(waterByDay);
        }
        // v12 drops the per-set log.
        //
        // There were two ways to record the same gym work: a row per scheduled
        // exercise per day, and a flat list of sets underneath it. Two records
        // of one thing is one record too many — they drift apart, and neither
        // is the answer to "what did I train". The scheduled row survives
        // because it is the one the screen ticks off, and the progress figures
        // are now read off the rows that were ticked, so they count work that
        // actually happened rather than work that was written down.
        //
        // The sets stored under the old log go with the table. That is data
        // loss, and it is deliberate.
        //
        // A database arriving from v1 never gets the table at all: the v2
        // branch above stopped creating it, so there is nothing here to drop
        // and `deleteTable` on a table that was never made is a no-op anyway.
        if (from < 12) {
          await m.deleteTable('exercise_sets');
        }
        if (from < 6) {
          await m.createTable(foods);
          // By hand, as always: `createTable` writes the table and nothing
          // else. `food_by_name` is unique, and without it the catalogue would
          // file a second "avena" every time the casing changed.
          await _createIndexIfMissing(foodByName);
        }
        // v13 turns the food catalogue into a food database.
        //
        // The old table quoted a food's macros against a free-text portion —
        // "1 plato", "150 g", or nothing at all. That is unusable as a
        // database: figures measured against an unknown weight cannot be
        // scaled to what was actually eaten, compared with each other, or
        // checked against a reference. Every food is quoted per 100 g now, and
        // an entry is that figure scaled by what went on the scale.
        //
        // Which is why the existing rows go rather than convert. Their macros
        // are for a weight nobody recorded, so reading them as per-100 g
        // figures would multiply a user's numbers by an arbitrary factor and
        // say nothing about having done it — a wrong figure that looks right
        // is worse than a missing one. There is no honest conversion, so there
        // is no conversion.
        //
        // The cost is small and it is bounded: these rows were a convenience
        // cache the app filled by itself, and what is lost is the typing that
        // filled them. `food_entries` is not touched. The record of what was
        // eaten survives this migration exactly as it was written, which is
        // the only part of the nutrition store that was ever irreplaceable.
        if (from >= 6 && from < 13) {
          await m.deleteTable('foods');
          await m.createTable(foods);
          // Dropping the table took its index with it, so it goes back up by
          // hand — and it has to, or the seed below would file a second
          // "Ñoquis" the first time the casing changed.
          await _createIndexIfMissing(foodByName);
        }
        if (from < 13) {
          await seedBuiltInFoods();
        }
        // v14 gives every record a UUID and an `updatedAt`
        // (STACK-APPS-DINAMICAS.md 1.1). Last, so it sees every table in the
        // shape the steps above left it in.
        // Before v14 touches `todo_tasks`: rebuilding a table restores the
        // indices it already had, and this one was written against `status`
        // — the column v14 is about to drop. v15 puts it back in today's
        // shape a few statements later.
        if (from < 15) {
          await customStatement('DROP INDEX IF EXISTS "task_project_lookup"');
        }
        if (from < 14) {
          await _giveEveryRecordAUuid(m);
        }
        // v15 turns the board's three columns from an enum into rows the
        // user owns, one board per project. Every task is pointed at its own
        // project's copy of the column its `status` named.
        if (from < 15) {
          await _rebuildBoardAsColumns(m);
        }
        // v16 gives a task a checklist, v17 lets a food entry be made of
        // several foods, v18 records the steps walked in a day and v19 the
        // days the user was away. None of them changes anything already
        // stored: a task with no checklist, an entry with no parts, a day
        // with no step count and a record with no holidays in it are what
        // every row written before this looks like.
        if (from < 16) {
          await m.createTable(taskChecklistItems);
          await _createIndexIdempotently(checklistByTask);
        }
        if (from < 17) {
          await m.createTable(foodEntryItems);
          await _createIndexIdempotently(entryItemByEntry);
        }
        if (from < 18) {
          await m.createTable(stepLogs);
          await m.createTable(stepGoals);
        }
        // v19 lets the user say they are away. Nothing already stored is a
        // break, and nothing stored means nothing is paused, which is what
        // every row written before this assumed.
        if (from < 19) {
          await m.createTable(vacationPeriods);
          await _createIndexIdempotently(vacationByStart);
        }
      });
    },
    beforeOpen: (details) async {
      // SQLite disables foreign keys per connection by default, which would
      // make every ON DELETE CASCADE above silently do nothing.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
