
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_exercise_repository.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import '../domain/exercise_stats.dart';

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

/// The training logged on the day the week strip points at.
final workoutDayProvider = FutureProvider<WorkoutDay>((ref) {
  ref.watch(exerciseRevisionProvider);

  return ref
      .watch(exerciseRepositoryProvider)
      .workoutFor(ref.watch(selectedDayProvider));
});

/// Write operations, kept out of the widgets.
class ExerciseActions {
  ExerciseActions(this._ref);

  final Ref _ref;

  ExerciseRepository get _repository => _ref.read(exerciseRepositoryProvider);

  Future<void> createExercise(ExerciseDraft draft) async {
    await _repository.createExercise(draft);
    _invalidate();
  }

  Future<void> updateExercise(int id, ExerciseDraft draft) async {
    await _repository.updateExercise(id, draft);
    _invalidate();
  }

  Future<void> deleteExercise(int id) async {
    await _repository.deleteExercise(id);
    _invalidate();
  }

  Future<void> logSet(int exerciseId, {required int reps, double? weight}) async {
    await _repository.logSet(
      _ref.read(selectedDayProvider),
      exerciseId: exerciseId,
      reps: reps,
      weight: weight,
    );
    _invalidate();
  }

  Future<void> updateSet(int id, {required int reps, double? weight}) async {
    await _repository.updateSet(id, reps: reps, weight: weight);
    _invalidate();
  }

  Future<void> deleteSet(int id) async {
    await _repository.deleteSet(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(exerciseRevisionProvider.notifier).update((v) => v + 1);
}

final exerciseActionsProvider = Provider<ExerciseActions>(ExerciseActions.new);
