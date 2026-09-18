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
    TodoTasks,
    TaskComments,
    NutritionGoals,
    FoodEntries,
    Foods,
    Exercises,
    ScheduledExercises,
    Disciplines,
    Medications,
    MedicationIntakes,
    HydrationGoals,
    WaterEntries,
    MeditationSessions,
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
  static const currentSchemaVersion = 14;

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

      await m.alterTable(
        TableMigration(
          table,
          newColumns: [byName['updated_at']!],
          columnTransformer: {
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
        if (from < 14) {
          await _giveEveryRecordAUuid(m);
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
