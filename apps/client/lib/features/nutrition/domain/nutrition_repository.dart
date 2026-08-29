import 'nutrition.dart';

/// The user-editable fields of a food entry.
class FoodDraft {
  const FoodDraft({
    required this.name,
    this.portion,
    this.macros = Macros.empty,
  });

  final String name;
  final String? portion;
  final Macros macros;
}

/// The port the nutrition module talks to.
abstract interface class NutritionRepository {
  /// The daily targets. Falls back to a sensible default when never set.
  Future<NutritionGoal> goal();

  Future<NutritionGoal> saveGoal(NutritionGoal goal);

  /// What was eaten on [day], in the order it was logged.
  Future<List<FoodEntry>> entriesFor(DateTime day);

  /// The day's entries together with the totals and the targets.
  Future<DailyNutrition> dayFor(DateTime day);

  Future<FoodEntry> addEntry(DateTime day, FoodDraft draft);

  Future<FoodEntry> updateEntry(int id, FoodDraft draft);

  Future<void> deleteEntry(int id);
}
