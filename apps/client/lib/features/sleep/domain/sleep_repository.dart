import '../../../core/time/date_range.dart';
import 'sleep_log.dart';
import 'sleep_stats.dart';

/// The port the sleep module talks to.
abstract interface class SleepRepository {
  /// The night registered for [day], or null if there is none.
  Future<SleepLog?> forDay(DateTime day);

  /// Registers or replaces the hours slept on [day].
  ///
  /// There is at most one record per day, so saving the same day again
  /// updates it rather than adding a second row.
  Future<SleepLog> save(DateTime day, double hours);

  /// The nights inside [range], ascending by date.
  Future<List<SleepLog>> inRange(DateRange range);

  /// The figures the history section shows for [range].
  Future<SleepStats> statsFor(DateRange range);
}
