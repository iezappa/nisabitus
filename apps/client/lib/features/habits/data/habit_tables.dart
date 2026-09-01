import 'package:drift/drift.dart';

/// A habit the user intends to repeat over time.
@DataClassName('HabitRow')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();
  TextColumn get category => text().withLength(max: 255).nullable()();

  /// Stored as the canonical wire name of HabitFrequency.
  TextColumn get frequency => text().withLength(max: 16)();

  /// How many times per period the habit is meant to be fulfilled.
  IntColumn get targetCount => integer().withDefault(const Constant(1))();

  /// After this day the habit is shown as finished. Cleared when the habit
  /// repeats forever.
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get repeatForever =>
      boolean().withDefault(const Constant(false))();

  /// Comma-separated weekday names. Empty means every day.
  TextColumn get repeatDays =>
      text().withLength(max: 100).withDefault(const Constant(''))();

  /// Free-form UI tag: habit, streak or pomodoro.
  TextColumn get type => text().withLength(max: 255).nullable()();

  /// Stored as the canonical wire name of HabitStatus.
  TextColumn get status => text().withLength(max: 16)();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get scheduledDate => dateTime()();
}

/// Proof that a habit was fulfilled on a given day.
///
/// This history is never deleted when the day rolls over: it is the source of
/// every progress chart.
@TableIndex(
  name: 'habit_completion_lookup',
  columns: {#habitId, #completionDate},
)
@DataClassName('HabitCompletionRow')
class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get completionDate => dateTime()();
}
