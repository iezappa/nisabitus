import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_exercise_repository.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import '../domain/exercise_stats.dart';
import '../domain/scheduled_exercise.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => DriftExerciseRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final exerciseRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view looks at.
final exerciseProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The figures behind the progress view, for the chosen window.
final exerciseStatsProvider = FutureProvider<ExerciseStats>((ref) {
  ref.watch(exerciseRevisionProvider);

  final range = ref
      .watch(exerciseProgressRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(exerciseRepositoryProvider).statsFor(range);
});

final exerciseCatalogueProvider = FutureProvider<List<Exercise>>((ref) {
  ref.watch(exerciseRevisionProvider);

  return ref.watch(exerciseRepositoryProvider).exercises();
});

/// What is written down for the day the week strip points at.
final scheduledExercisesProvider = FutureProvider<List<ScheduledExercise>>((
  ref,
) {
  ref.watch(exerciseRevisionProvider);

  return ref
      .watch(exerciseRepositoryProvider)
      .scheduledFor(ref.watch(selectedDayProvider));
});

/// Write operations, kept out of the widgets.
class ExerciseActions {
  ExerciseActions(this._ref);

  final Ref _ref;

  ExerciseRepository get _repository => _ref.read(exerciseRepositoryProvider);

  /// Returns what it created, so a caller that needs to select it — the
  /// scheduling form, adding a movement it did not have — does not have to
  /// re-read the catalogue and guess which row is the new one.
  Future<Exercise> createExercise(ExerciseDraft draft) async {
    final exercise = await _repository.createExercise(draft);
    _invalidate();

    return exercise;
  }

  Future<void> updateExercise(int id, ExerciseDraft draft) async {
    await _repository.updateExercise(id, draft);
    _invalidate();
  }

  Future<void> deleteExercise(int id) async {
    await _repository.deleteExercise(id);
    _invalidate();
  }

  Future<void> schedule(
    ScheduledExerciseDraft draft, {
    ExerciseRecurrence? recurrence,
  }) async {
    await _repository.schedule(
      _ref.read(selectedDayProvider),
      draft,
      recurrence: recurrence,
    );
    _invalidate();
  }

  Future<void> updateScheduled(int id, ScheduledExerciseDraft draft) async {
    await _repository.updateScheduled(id, draft);
    _invalidate();
  }

  Future<void> complete(int id, ExerciseCompletion completion) async {
    await _repository.complete(id, completion);
    _invalidate();
  }

  Future<void> reopen(int id) async {
    await _repository.reopen(id);
    _invalidate();
  }

  Future<void> deleteScheduled(int id) async {
    await _repository.deleteScheduled(id);
    _invalidate();
  }

  Future<void> stopRecurrence(int id) async {
    await _repository.stopRecurrence(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(exerciseRevisionProvider.notifier).update((v) => v + 1);
}

final exerciseActionsProvider = Provider<ExerciseActions>(ExerciseActions.new);
