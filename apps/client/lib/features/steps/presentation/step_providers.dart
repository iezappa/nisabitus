import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_step_repository.dart';
import '../domain/step_log.dart';
import '../domain/step_repository.dart';
import '../domain/step_stats.dart';

final stepRepositoryProvider = Provider<StepRepository>(
  (ref) => DriftStepRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final stepRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the report is looking at.
final stepReportRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The count written down for the day the strip points at, if any.
final stepsForSelectedDayProvider = FutureProvider<StepLog?>((ref) {
  ref.watch(stepRevisionProvider);

  return ref
      .watch(stepRepositoryProvider)
      .forDay(ref.watch(selectedDayProvider));
});

final stepGoalProvider = FutureProvider<StepGoal>((ref) {
  ref.watch(stepRevisionProvider);

  return ref.watch(stepRepositoryProvider).goal();
});

final stepStatsProvider = FutureProvider<StepStats>((ref) {
  ref.watch(stepRevisionProvider);

  final range = ref
      .watch(stepReportRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(stepRepositoryProvider).statsFor(range);
});

/// Write operations, kept out of the widgets.
class StepActions {
  StepActions(this._ref);

  final Ref _ref;

  StepRepository get _repository => _ref.read(stepRepositoryProvider);

  Future<void> save(int steps) async {
    await _repository.save(_ref.read(selectedDayProvider), steps);
    _invalidate();
  }

  /// Takes the day's count back, rather than correcting it to zero.
  ///
  /// Zero is a day of no walking, which is a thing that happens and is worth
  /// recording. Removing the row is how a number typed by mistake stops
  /// being one of the days the averages are taken over.
  Future<void> clear() async {
    await _repository.clear(_ref.read(selectedDayProvider));
    _invalidate();
  }

  Future<void> saveGoal(int steps) async {
    await _repository.saveGoal(StepGoal(steps: steps));
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(stepRevisionProvider.notifier).update((value) => value + 1);
}

final stepActionsProvider = Provider<StepActions>(StepActions.new);
