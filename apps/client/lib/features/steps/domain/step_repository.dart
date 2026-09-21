import '../../../core/time/date_range.dart';
import 'step_log.dart';
import 'step_stats.dart';

/// The port the steps module talks to.
abstract interface class StepRepository {
  /// The steps registered for [day], or null if there are none.
  ///
  /// Null is not zero: a day nobody wrote down is not a day of no walking,
  /// and every figure in [StepStats] rests on the difference.
  Future<StepLog?> forDay(DateTime day);

  /// Registers or replaces the steps walked on [day].
  Future<StepLog> save(DateTime day, int steps);

  /// Removes the count for [day], which is how a number typed by mistake is
  /// taken back rather than corrected to zero.
  Future<void> clear(DateTime day);

  /// The days inside [range] that were written down, ascending.
  Future<List<StepLog>> inRange(DateRange range);

  /// The daily target. Falls back to a sensible default when never set.
  Future<StepGoal> goal();

  Future<StepGoal> saveGoal(StepGoal goal);

  /// The figures the report shows for [range].
  Future<StepStats> statsFor(DateRange range);
}
