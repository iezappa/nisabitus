import 'package:drift/drift.dart';

/// One session of something practised for a time, on one day.
///
/// Kept apart from the scheduled exercises on purpose: a swim has a duration
/// and a distance and no sets, a squat has sets and no kilometres, and one
/// table for both is one table with half its columns null on every row.
///
/// No catalogue behind it, unlike exercises: what is practised is written as
/// it is called, and "Natación" does not need a definition to be logged.
@DataClassName('DisciplineRow')
@TableIndex(name: 'discipline_by_day', columns: {#scheduledDate})
@TableIndex(name: 'discipline_by_group', columns: {#recurrenceGroupId})
class Disciplines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  DateTimeColumn get scheduledDate => dateTime()();

  IntColumn get durationMinutes => integer()();

  /// Null when the session is not measured in distance. A yoga class has a
  /// duration and no kilometres, and zero would claim it was measured.
  RealColumn get distanceKm => real().nullable()();

  TextColumn get notes => text().withLength(max: 1000).nullable()();
  TextColumn get feedback => text().withLength(max: 1000).nullable()();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  TextColumn get recurrenceGroupId => text().withLength(max: 64).nullable()();
  TextColumn get repeatDays =>
      text().withLength(max: 100).withDefault(const Constant(''))();
  BoolColumn get repeatForever =>
      boolean().withDefault(const Constant(false))();
}
