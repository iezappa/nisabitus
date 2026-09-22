import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// A stretch of days the user asked not to be judged on.
///
/// A range and not a flag, which is the whole point: a flag can say "I am
/// away now" but cannot say whether last Tuesday was a day off, and every
/// figure the app draws is about the past. With the days written down, a
/// streak can be asked afterwards whether the gap it is looking at was a
/// holiday.
///
/// [endDate] is null while the break is still going. The user turns the mode
/// on without knowing when they will be back, and a made-up end date would
/// either cut the holiday short or extend it past the day they returned.
@DataClassName('VacationPeriodRow')
@TableIndex(name: 'vacation_by_start', columns: {#startDate})
class VacationPeriods extends Table with RecordColumns {
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// What the break was, in the user's own words: "Viaje", "Gripe".
  TextColumn get note => text().withLength(max: 255).nullable()();
}
