import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// The daily water target.
///
/// A single row: there is one user and one target. The id is pinned so
/// saving always replaces it rather than piling up revisions.
@DataClassName('HydrationGoalRow')
class HydrationGoals extends Table with SingletonColumns {
  IntColumn get millilitres => integer().withDefault(const Constant(2000))();
}

/// One drink on one day.
///
/// A row per drink rather than one editable total per day: water is drunk in
/// glasses through the day, and a single number typed at the end of it is a
/// guess, not a record.
@DataClassName('WaterEntryRow')
@TableIndex(name: 'water_by_day', columns: {#date})
class WaterEntries extends Table with RecordColumns {
  DateTimeColumn get date => dateTime()();
  IntColumn get millilitres => integer()();
}
