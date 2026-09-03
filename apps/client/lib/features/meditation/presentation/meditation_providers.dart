import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_meditation_repository.dart';
import '../domain/meditation.dart';
import '../domain/meditation_repository.dart';
import '../domain/meditation_stats.dart';

final meditationRepositoryProvider = Provider<MeditationRepository>(
  (ref) => DriftMeditationRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final meditationRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view looks at.
final meditationProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The figures behind the progress view, for the chosen window.
final meditationStatsProvider = FutureProvider<MeditationStats>((ref) {
  ref.watch(meditationRevisionProvider);

  final range = ref
      .watch(meditationProgressRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(meditationRepositoryProvider).statsFor(range);
});

/// The day the week strip is pointing at.
final meditationDayProvider = FutureProvider<DailyMeditation>((ref) {
  ref.watch(meditationRevisionProvider);

  return ref
      .watch(meditationRepositoryProvider)
      .dayFor(ref.watch(selectedDayProvider));
});

/// Write operations, kept out of the widgets.
class MeditationActions {
  MeditationActions(this._ref);

  final Ref _ref;

  MeditationRepository get _repository =>
      _ref.read(meditationRepositoryProvider);

  Future<void> add(MeditationDraft draft) async {
    await _repository.add(_ref.read(selectedDayProvider), draft);
    _invalidate();
  }

  Future<void> update(int id, MeditationDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(meditationRevisionProvider.notifier).update((v) => v + 1);
}

final meditationActionsProvider = Provider<MeditationActions>(
  MeditationActions.new,
);
