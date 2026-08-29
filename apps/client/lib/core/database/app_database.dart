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
  AppDatabase() : super(driftDatabase(name: 'nisabit'));

  /// Used by tests to run against a throwaway in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 added the nutrition and exercise tables. Everything already
      // stored is untouched: this only creates what did not exist.
      if (from < 2) {
        await m.createTable(nutritionGoals);
        await m.createTable(foodEntries);
        await m.createTable(exercises);
        await m.createTable(exerciseSets);
      }
      // v3 added medication and supplement tracking.
      if (from < 3) {
        await m.createTable(medications);
        await m.createTable(medicationIntakes);
      }
      // v4 records when a task was finished. Existing tasks keep a null
      // date: their status is known, the moment is not, and inventing one
      // would put fictional work on the chart.
      if (from < 4) {
        await m.addColumn(todoTasks, todoTasks.completedAt);
      }
    },
    beforeOpen: (details) async {
      // SQLite disables foreign keys per connection by default, which would
      // make every ON DELETE CASCADE above silently do nothing.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
