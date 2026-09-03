import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/discipline/data/discipline_tables.dart';
import '../../features/exercise/data/exercise_tables.dart';
import '../../features/habits/data/habit_tables.dart';
import '../../features/hydration/data/hydration_tables.dart';
import '../../features/journal/data/journal_tables.dart';
import '../../features/medication/data/medication_tables.dart';
import '../../features/meditation/data/meditation_tables.dart';
import '../../features/nutrition/data/nutrition_tables.dart';
import '../../features/pomodoro/data/pomodoro_tables.dart';
import '../../features/sleep/data/sleep_tables.dart';
import '../../features/streaks/data/streak_tables.dart';
import '../../features/todo/data/todo_tables.dart';

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
    ExerciseSets,
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
  AppDatabase() : super(driftDatabase(name: 'nisabitus', web: _web));

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
  static final _web = DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  );

  /// Used by tests to run against a throwaway in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
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
        await m.createTable(exerciseSets);
        await m.create(foodEntryByDay);
        await m.create(exerciseSetByDay);
      }
      // v3 added medication and supplement tracking.
      if (from < 3) {
        await m.createTable(medications);
        await m.createTable(medicationIntakes);
        await m.create(intakeByDay);
      }
      // v4 records when a task was finished. Existing tasks keep a null
      // date: their status is known, the moment is not, and inventing one
      // would put fictional work on the chart.
      if (from < 4) {
        await m.addColumn(todoTasks, todoTasks.completedAt);
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
        await m.addColumn(medications, medications.activeFrom);
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
        await m.addColumn(foodEntries, foodEntries.meal);
      }
      // v9 adds training routines: what to do, kept apart from what was
      // done. Two new columns go onto tables that already existed — a
      // reference video for the movement, and how a set felt — and both are
      // null for everything already stored, which is honest: nobody was
      // asked, so nobody answered.
      //
      // Same split as v5 and v6: `createTable` builds `exercises` and
      // `exercise_sets` from today's definition, these columns included, so
      // only a database that already had those tables needs them added.
      if (from >= 2 && from < 9) {
        await m.addColumn(exercises, exercises.videoUrl);
        await m.addColumn(exerciseSets, exerciseSets.note);
      }
      // v11 adds what is practised for a time rather than counted in sets:
      // swimming, running, cycling. Its own table, because a swim has a
      // duration and a distance and no sets — one table for both shapes
      // would be one table with half its columns null on every row.
      if (from < 11) {
        await m.createTable(disciplines);
        await m.create(disciplineByDay);
        await m.create(disciplineByGroup);
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
        await m.create(scheduledExerciseByDay);
        await m.create(scheduledExerciseByGroup);
      }
      // v8 records meditation. Nothing existing changes, for the same
      // reason as v7: an app that never had a practice log has no sittings
      // to migrate.
      if (from < 8) {
        await m.createTable(meditationSessions);
        await m.create(meditationByDay);
      }
      // v7 records water. Nothing existing changes: an app that never had a
      // hydration log has no water to migrate, and a day with no drinks
      // stays a day nobody wrote anything down on.
      if (from < 7) {
        await m.createTable(hydrationGoals);
        await m.createTable(waterEntries);
        await m.create(waterByDay);
      }
      if (from < 6) {
        await m.createTable(foods);
        // By hand, as always: `createTable` writes the table and nothing
        // else. `food_by_name` is unique, and without it the catalogue would
        // file a second "avena" every time the casing changed.
        await m.create(foodByName);
      }
    },
    beforeOpen: (details) async {
      // SQLite disables foreign keys per connection by default, which would
      // make every ON DELETE CASCADE above silently do nothing.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
