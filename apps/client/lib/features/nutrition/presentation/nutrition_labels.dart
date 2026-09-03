import '../../../l10n/app_localizations.dart';
import '../domain/meal.dart';

/// Words for the nutrition enums, kept at the edge so the domain stays free
/// of display concerns.
extension NutritionLabels on AppLocalizations {
  String mealName(Meal meal) => switch (meal) {
    Meal.breakfast => nutritionMealBreakfast,
    Meal.lunch => nutritionMealLunch,
    Meal.snack => nutritionMealSnack,
    Meal.dinner => nutritionMealDinner,
  };

  /// The heading a group of entries sits under, including the group of
  /// entries that never said which meal they were.
  String mealHeading(Meal? meal) =>
      meal == null ? nutritionUnassigned : mealName(meal);
}
