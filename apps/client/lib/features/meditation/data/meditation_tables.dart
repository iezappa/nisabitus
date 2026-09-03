import 'package:drift/drift.dart';

/// One sat session on one day.
///
/// A row per session rather than one total per day: two ten-minute sittings
/// are two things that happened, and collapsing them loses which day looked
/// like a habit and which looked like one long effort.
@DataClassName('MeditationSessionRow')
@TableIndex(name: 'meditation_by_day', columns: {#date})
class MeditationSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get minutes => integer()();

  /// How it went, in the user's own words.
  TextColumn get note => text().withLength(max: 1000).nullable()();
}
