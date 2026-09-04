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

  /// Every food in the database, by name.
  ///
  /// Ordered alphabetically rather than by use: it is a reference table of
  /// eighty-odd foods now, read by looking one up, and an order that shuffles
  /// with what was eaten this morning makes looking one up harder.
  Future<List<Food>> foods();

  /// Writes [food] down, or corrects the one already there.
  ///
  /// An id of zero is a food the database does not have yet. Matching is
  /// otherwise by id, with the case-folded name kept unique underneath:
  /// "avena" and "Avena" are one food, not two.
  Future<Food> saveFood(Food food);

  /// Removes a food from the database.
  ///
  /// It cascades onto nothing. Every entry copied its figures when it was
  /// logged, so what was eaten survives a food being deleted, which is what
  /// the confirmation tells the user.
  Future<void> deleteFood(int id);
}
