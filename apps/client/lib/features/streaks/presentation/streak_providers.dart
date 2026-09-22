import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../vacation/presentation/vacation_providers.dart';
import '../data/drift_streak_repository.dart';
import '../domain/streak.dart';
import '../domain/streak_repository.dart';

final streakRepositoryProvider = Provider<StreakRepository>(
  // Given the breaks, so a run the user was away for survives the gap.
  (ref) => DriftStreakRepository(
    ref.watch(databaseProvider),
    vacations: ref.watch(vacationRepositoryProvider),
  ),
);

/// Incremented after every write so dependent queries refetch.
final streaksRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view is looking at.
final streakProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// One line per streak that moved inside the window.
final streakSeriesProvider = FutureProvider<List<StreakSeries>>((ref) {
  ref.watch(streaksRevisionProvider);

  return ref
      .watch(streakRepositoryProvider)
      .chartSeries(ref.watch(streakProgressRangeProvider).toDateRange());
});

final streaksProvider = FutureProvider<List<Streak>>((ref) {
  ref.watch(streaksRevisionProvider);

  return ref.watch(streakRepositoryProvider).list();
});

/// Write operations, kept out of the widgets.
class StreakActions {
  StreakActions(this._ref);

  final Ref _ref;

  StreakRepository get _repository => _ref.read(streakRepositoryProvider);

  Future<void> create(String name) async {
    await _repository.create(name);
    _invalidate();
  }

  Future<void> rename(String id, String name) async {
    await _repository.rename(id, name);
    _invalidate();
  }

  Future<void> increment(String id, {DateTime? on}) async {
    await _repository.increment(id, on: on);
    _invalidate();
  }

  Future<void> reset(String id) async {
    await _repository.reset(id);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(streaksRevisionProvider.notifier).update((value) => value + 1);
}

final streakActionsProvider = Provider<StreakActions>(StreakActions.new);
