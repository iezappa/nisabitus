import 'package:drift/drift.dart';

/// The journal entry for a single day.
///
/// At most one entry per day. The six fields of the entry are serialized into
/// [content] as markdown-style sections.
@DataClassName('MoodEntryRow')
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get date => dateTime().unique()();
}
