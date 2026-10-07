import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

@DataClassName('CheatsheetNoteRow')
class CheatsheetNotes extends Table with RecordColumns {
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get folder => text().withDefault(const Constant('Imported'))();
  TextColumn get sourceName => text().nullable()();
  TextColumn get format => text()();
  DateTimeColumn get importedAt => dateTime()();
}
