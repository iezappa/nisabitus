import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_hydration_repository.dart';
import '../domain/hydration.dart';
import '../domain/hydration_repository.dart';
import '../domain/hydration_stats.dart';

final hydrationRepositoryProvider = Provider<HydrationRepository>(
  (ref) => DriftHydrationRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final hydrationRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view looks at.
final hydrationProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The figures behind the progress view, for the chosen window.
final hydrationStatsProvider = FutureProvider<HydrationStats>((ref) {
  ref.watch(hydrationRevisionProvider);

  final range = ref
      .watch(hydrationProgressRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(hydrationRepositoryProvider).statsFor(range);
});

/// The day the week strip is pointing at, totalled against the target.
final hydrationDayProvider = FutureProvider<DailyHydration>((ref) {
  ref.watch(hydrationRevisionProvider);

  return ref
      .watch(hydrationRepositoryProvider)
      .dayFor(ref.watch(selectedDayProvider));
});

/// Write operations, kept out of the widgets.
class HydrationActions {
  HydrationActions(this._ref);

  final Ref _ref;

  HydrationRepository get _repository => _ref.read(hydrationRepositoryProvider);

  Future<void> saveGoal(HydrationGoal goal) async {
    await _repository.saveGoal(goal);
    _invalidate();
  }

  Future<void> add(int millilitres) async {
    await _repository.addEntry(_ref.read(selectedDayProvider), millilitres);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.deleteEntry(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(hydrationRevisionProvider.notifier).update((v) => v + 1);
}

final hydrationActionsProvider = Provider<HydrationActions>(
  HydrationActions.new,
);
