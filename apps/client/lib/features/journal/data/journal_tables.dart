import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// The journal entry for a single day.
///
/// At most one entry per day. The six fields of the entry are serialized into
/// [content] as markdown-style sections.
@DataClassName('MoodEntryRow')
class MoodEntries extends Table with RecordColumns {
  TextColumn get content => text()();
  DateTimeColumn get date => dateTime().unique()();
}
