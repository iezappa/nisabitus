import 'package:drift/drift.dart';

/// An exercise the user performs, described once and logged many times.
@DataClassName('ExerciseRow')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();

  /// Free text, so the user's own vocabulary works.
  TextColumn get muscleGroup => text().withLength(max: 255).nullable()();

  /// A video showing how the movement is done.
  ///
  /// A property of the movement, not of a day or of a plan: the way a squat
  /// is performed does not change because it is Tuesday, and holding the link
  /// here means it is right once instead of copied into every routine that
  /// ever prescribes it.
  TextColumn get videoUrl => text().withLength(max: 2000).nullable()();
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

  /// How it felt, in the user's own words.
  ///
  /// On the set and not on the routine, because a plan cannot feel anything.
  /// This is the half of the record that says the weight moved but the last
  /// rep was ugly, which no target will ever tell you.
  TextColumn get note => text().withLength(max: 1000).nullable()();
}

/// One exercise on one day: what to do, and what happened.
///
/// The same row is both, which is the whole point. A repetition is written
/// down as one of these per day rather than kept as a plan the day is
/// compared against — so correcting tomorrow leaves yesterday exactly as it
/// was lived, and no history has to be reconstructed to read a past week.
///
/// It is the shape habits already use here: a scheduled date, the days it
/// repeats on, and a flag for whether it is done.
@DataClassName('ScheduledExerciseRow')
@TableIndex(name: 'scheduled_exercise_by_day', columns: {#scheduledDate})
@TableIndex(name: 'scheduled_exercise_by_group', columns: {#recurrenceGroupId})
class ScheduledExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The movement, from the catalogue. The reference video and the muscle
  /// group live there, so they are right once instead of copied onto every
  /// day the exercise comes round.
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get scheduledDate => dateTime()();

  IntColumn get sets => integer()();
  IntColumn get reps => integer()();

  /// Null when the movement carries no external load, which is not zero.
  RealColumn get weightKg => real().nullable()();

  /// Rate of perceived exertion, 1 to 10. How hard it actually was, which no
  /// weight on its own can say.
  IntColumn get rpe => integer().nullable()();

  /// Cues written when planning: depth, tempo, what to watch for.
  TextColumn get comments => text().withLength(max: 1000).nullable()();

  /// How it went, written afterwards.
  TextColumn get feedback => text().withLength(max: 1000).nullable()();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// Ties the copies of one repetition together, so a series can be stopped
  /// from a day forward without touching what came before it.
  TextColumn get recurrenceGroupId => text().withLength(max: 64).nullable()();

  /// Comma-separated weekday names, the same encoding habits use.
  TextColumn get repeatDays =>
      text().withLength(max: 100).withDefault(const Constant(''))();

  BoolColumn get repeatForever =>
      boolean().withDefault(const Constant(false))();
}
