import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/exercise/data/exercise_tables.dart';
import '../../features/habits/data/habit_tables.dart';
import '../../features/journal/data/journal_tables.dart';
import '../../features/medication/data/medication_tables.dart';
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
    Exercises,
    ExerciseSets,
    Medications,
    MedicationIntakes,
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
  int get schemaVersion => 5;

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
    },
    beforeOpen: (details) async {
      // SQLite disables foreign keys per connection by default, which would
      // make every ON DELETE CASCADE above silently do nothing.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
