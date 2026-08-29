import 'package:drift/drift.dart';

/// An exercise the user performs, described once and logged many times.
@DataClassName('ExerciseRow')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();

  /// Free text, so the user's own vocabulary works.
  TextColumn get muscleGroup => text().withLength(max: 255).nullable()();
}

/// One set performed on one day.
///
/// Sets are stored flat rather than nested under a workout: the unit the
/// user actually records is "this many reps at this weight", and a day's
/// work is whatever sets carry that date.
@DataClassName('ExerciseSetRow')
@TableIndex(name: 'exercise_set_by_day', columns: {#date, #exerciseId})
class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();

  /// Order within the day, so sets read in the order they were done.
  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get reps => integer()();

  /// Null for bodyweight work.
  RealColumn get weight => real().nullable()();
}
