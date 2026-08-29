import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_sleep_repository.dart';
import '../domain/sleep_log.dart';
import '../domain/sleep_repository.dart';
import '../domain/sleep_stats.dart';

final sleepRepositoryProvider = Provider<SleepRepository>(
  (ref) => DriftSleepRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final sleepRevisionProvider = StateProvider<int>((ref) => 0);

/// The history window. The spec offers the last 7, 30 or 365 days.
final sleepHistoryRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The night registered for the day the strip points at, if any.
final sleepForSelectedDayProvider = FutureProvider<SleepLog?>((ref) {
  ref.watch(sleepRevisionProvider);

  return ref
      .watch(sleepRepositoryProvider)
      .forDay(ref.watch(selectedDayProvider));
});

final sleepStatsProvider = FutureProvider<SleepStats>((ref) {
  ref.watch(sleepRevisionProvider);

  final range = ref
      .watch(sleepHistoryRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(sleepRepositoryProvider).statsFor(range);
});

/// Write operations, kept out of the widgets.
class SleepActions {
  SleepActions(this._ref);

  final Ref _ref;

  Future<void> save(double hours) async {
    await _ref
        .read(sleepRepositoryProvider)
        .save(_ref.read(selectedDayProvider), hours);
    _ref.read(sleepRevisionProvider.notifier).update((value) => value + 1);
  }
}

final sleepActionsProvider = Provider<SleepActions>(SleepActions.new);
