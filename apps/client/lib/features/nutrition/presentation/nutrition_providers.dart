import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_nutrition_repository.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_repository.dart';
import '../domain/nutrition_stats.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => DriftNutritionRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final nutritionRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view looks at.
final nutritionProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The figures behind the progress view, for the chosen window.
final nutritionStatsProvider = FutureProvider<NutritionStats>((ref) {
  ref.watch(nutritionRevisionProvider);

  final range = ref
      .watch(nutritionProgressRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(nutritionRepositoryProvider).statsFor(range);
});

/// Everything the catalogue has learned, most recently eaten first.
final nutritionFoodsProvider = FutureProvider<List<Food>>((ref) {
  ref.watch(nutritionRevisionProvider);

  return ref.watch(nutritionRepositoryProvider).foods();
});

/// The day the week strip is pointing at, totalled against the targets.
final nutritionDayProvider = FutureProvider<DailyNutrition>((ref) {
  ref.watch(nutritionRevisionProvider);

  return ref
      .watch(nutritionRepositoryProvider)
      .dayFor(ref.watch(selectedDayProvider));
});

/// Write operations, kept out of the widgets.
class NutritionActions {
  NutritionActions(this._ref);

  final Ref _ref;

  NutritionRepository get _repository => _ref.read(nutritionRepositoryProvider);

  Future<void> saveGoal(NutritionGoal goal) async {
    await _repository.saveGoal(goal);
    _invalidate();
  }

  Future<void> add(FoodDraft draft) async {
    await _repository.addEntry(_ref.read(selectedDayProvider), draft);
    _invalidate();
  }

  Future<void> update(int id, FoodDraft draft) async {
    await _repository.updateEntry(id, draft);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.deleteEntry(id);
    _invalidate();
  }

  /// Drops a food from the catalogue. What was already eaten is untouched:
  /// the catalogue is a convenience, not the record.
  Future<void> forgetFood(int id) async {
    await _repository.forgetFood(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(nutritionRevisionProvider.notifier).update((v) => v + 1);
}

final nutritionActionsProvider = Provider<NutritionActions>(
  NutritionActions.new,
);
