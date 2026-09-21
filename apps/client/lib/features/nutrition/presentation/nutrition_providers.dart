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

/// Every food in the database, by name.
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

  Future<void> add(FoodDraft draft, {bool keepAsDish = false}) async {
    await _repository.addEntry(_ref.read(selectedDayProvider), draft);
    await _keepAsDish(draft, keepAsDish);
    _invalidate();
  }

  Future<void> update(
    String id,
    FoodDraft draft, {
    bool keepAsDish = false,
  }) async {
    await _repository.updateEntry(id, draft);
    await _keepAsDish(draft, keepAsDish);
    _invalidate();
  }

  /// Files a composed plate in the food database as a dish of its own.
  ///
  /// Two separate writes on purpose, not one: what was eaten and what the
  /// database holds are different records with different lifetimes, and the
  /// whole nutrition module rests on keeping them apart. This only happens
  /// when the user ticked the box.
  ///
  /// The dish is quoted per 100 g of the combined weight, which is what makes
  /// it pickable and scalable like every other food. A plate with no weight
  /// has no such figure, and [FoodPartsReading.per100g] says so by returning
  /// null rather than inventing one.
  Future<void> _keepAsDish(FoodDraft draft, bool keep) async {
    if (!keep || draft.parts.length < 2) return;

    final parts = [
      for (final (index, part) in draft.parts.indexed)
        FoodPart(
          id: '$index',
          name: part.name,
          grams: part.grams,
          per100g: part.per100g,
        ),
    ];
    final per100g = parts.per100g;
    if (per100g == null) return;

    await _repository.saveFood(
      Food(id: Food.unsaved, name: draft.name, per100g: per100g),
    );
  }

  Future<void> delete(String id) async {
    await _repository.deleteEntry(id);
    _invalidate();
  }

  /// Writes down a food, or corrects the one already there.
  Future<void> saveFood(Food food) async {
    await _repository.saveFood(food);
    _invalidate();
  }

  /// Drops a food from the database. What was already eaten is untouched:
  /// the database is a reference, not the record.
  Future<void> deleteFood(String id) async {
    await _repository.deleteFood(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(nutritionRevisionProvider.notifier).update((v) => v + 1);
}

final nutritionActionsProvider = Provider<NutritionActions>(
  NutritionActions.new,
);
