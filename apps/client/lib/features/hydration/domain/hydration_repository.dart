import '../../../core/time/date_range.dart';
import 'hydration.dart';
import 'hydration_stats.dart';

/// The port the hydration module talks to.
abstract interface class HydrationRepository {
  /// The daily target. Falls back to a sensible default when never set.
  Future<HydrationGoal> goal();

  Future<HydrationGoal> saveGoal(HydrationGoal goal);

  /// What was drunk on [day], in the order it was logged.
  Future<List<WaterEntry>> entriesFor(DateTime day);

  /// The day's drinks together with the total and the target.
  Future<DailyHydration> dayFor(DateTime day);

  Future<WaterEntry> addEntry(DateTime day, int millilitres);

  Future<void> deleteEntry(int id);

  /// The figures the progress view shows for [range].
  Future<HydrationStats> statsFor(DateRange range);
}
