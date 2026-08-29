import '../../../core/time/date_range.dart';

/// A set of macronutrient figures, used both as a target and as a total.
///
/// Grams for the three macros, kilocalories for energy.
class Macros {
  const Macros({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  static const empty = Macros();

  Macros operator +(Macros other) => Macros(
    calories: calories + other.calories,
    protein: protein + other.protein,
    carbs: carbs + other.carbs,
    fat: fat + other.fat,
  );

  /// How far a total has come towards a target, capped at one.
  ///
  /// Capped because the bar is a bar: past the target the number keeps
  /// climbing but the fill has nowhere left to go.
  double ratioTo(int target) =>
      target <= 0 ? 0 : (calories / target).clamp(0.0, 1.0);

  bool get isEmpty =>
      calories == 0 && protein == 0 && carbs == 0 && fat == 0;

  @override
  bool operator ==(Object other) =>
      other is Macros &&
      other.calories == calories &&
      other.protein == protein &&
      other.carbs == carbs &&
      other.fat == fat;

  @override
  int get hashCode => Object.hash(calories, protein, carbs, fat);

  @override
  String toString() =>
      'Macros($calories kcal, P$protein C$carbs F$fat)';
}

/// The daily targets the user is aiming at.
class NutritionGoal {
  NutritionGoal({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  }) {
    for (final (value, field) in [
      (calories, 'calories'),
      (protein, 'protein'),
      (carbs, 'carbs'),
      (fat, 'fat'),
    ]) {
      if (value < 0 || value > 20000) {
        throw ArgumentError.value(value, field, 'Must be between 0 and 20000');
      }
    }
  }

  static final fallback = NutritionGoal(
    calories: 2000,
    protein: 120,
    carbs: 220,
    fat: 70,
  );

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  bool get isUnset => calories == 0 && protein == 0 && carbs == 0 && fat == 0;
}

/// Something eaten on a given day.
class FoodEntry {
  FoodEntry({
    required this.id,
    required DateTime date,
    required String name,
    required this.macros,
    this.portion,
  }) : date = dateOnly(date),
       name = _validateName(name);

  final int id;
  final DateTime date;
  final String name;

  /// Free text: "150 g", "1 plato", "2 unidades".
  final String? portion;

  final Macros macros;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  FoodEntry copyWith({int? id}) => FoodEntry(
    id: id ?? this.id,
    date: date,
    name: name,
    portion: portion,
    macros: macros,
  );
}

/// What one day of eating adds up to, against the targets.
class DailyNutrition {
  const DailyNutrition({
    required this.entries,
    required this.total,
    required this.goal,
  });

  factory DailyNutrition.from(List<FoodEntry> entries, NutritionGoal goal) =>
      DailyNutrition(
        entries: entries,
        total: entries.fold(Macros.empty, (sum, e) => sum + e.macros),
        goal: goal,
      );

  final List<FoodEntry> entries;
  final Macros total;
  final NutritionGoal goal;

  bool get isEmpty => entries.isEmpty;

  double get caloriesRatio => _ratio(total.calories, goal.calories);
  double get proteinRatio => _ratio(total.protein, goal.protein);
  double get carbsRatio => _ratio(total.carbs, goal.carbs);
  double get fatRatio => _ratio(total.fat, goal.fat);

  /// What is left of the day's energy budget. Negative once it is spent.
  int get caloriesRemaining => goal.calories - total.calories;

  static double _ratio(int value, int target) =>
      target <= 0 ? 0 : (value / target).clamp(0.0, 1.0);
}
