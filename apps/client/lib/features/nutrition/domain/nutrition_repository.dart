import '../../../core/time/date_range.dart';
import 'meal.dart';
import 'nutrition.dart';
import 'nutrition_stats.dart';

/// The user-editable fields of a food entry.
class FoodDraft {
  const FoodDraft({
    required this.name,
    this.portion,
    this.macros = Macros.empty,
    this.meal,
  });

  final String name;
  final String? portion;
  final Macros macros;

  /// Which meal it belongs to. Null is allowed and means the same as
  /// everywhere else: nobody said.
  final Meal? meal;
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

  /// The figures the progress view shows for [range].
  Future<NutritionStats> statsFor(DateRange range);

  /// Everything the catalogue has learned, most recently eaten first.
  ///
  /// Ordered by use rather than alphabetically: a list of foods is read to
  /// find the one you eat every morning, not to browse it.
  Future<List<Food>> foods();

  /// Files [food] in the catalogue, or updates the one already there.
  ///
  /// Matching is by name, case-insensitively: eating "avena" the day after
  /// "Avena" is eating the same thing twice, not discovering a second food.
  ///
  /// [eatenOn] is what [foods] orders by, so the picker is ordered by when
  /// each food was last actually eaten rather than by when the row happened
  /// to be written. Logging a forgotten lunch from last week does not push
  /// that food to the top: the later of the two dates wins.
  Future<Food> rememberFood(Food food, {DateTime? eatenOn});

  Future<void> forgetFood(int id);
}
