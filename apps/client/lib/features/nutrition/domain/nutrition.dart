import '../../../core/time/date_range.dart';
import 'food_portion.dart';
import 'meal.dart';

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

  bool get isEmpty => calories == 0 && protein == 0 && carbs == 0 && fat == 0;

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
  String toString() => 'Macros($calories kcal, P$protein C$carbs F$fat)';
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
    this.meal,
    this.parts = const [],
  }) : date = dateOnly(date),
       name = _validateName(name);

  final String id;
  final DateTime date;
  final String name;

  /// Free text: "150 g", "1 plato", "2 unidades".
  final String? portion;

  /// What the entry was worth. Authoritative, parts or no parts.
  ///
  /// When [parts] is not empty this is their sum, worked out once when the
  /// entry was written and stored — not recomputed on every read. The parts
  /// carry copies of what each food was made of at the time, so the total
  /// and its explanation can never drift from each other.
  final Macros macros;

  /// The foods this entry was made of, in the order they were added.
  ///
  /// Empty for an entry typed whole, which is every entry written before v17
  /// and anything still written by hand. Emptiness is not a missing value: a
  /// plate nobody broke down is a plate nobody broke down.
  final List<FoodPart> parts;

  /// Which meal this belonged to, or null for an entry written before the
  /// app asked. Null is not "breakfast": it is nobody having said.
  final Meal? meal;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  /// Whether the entry says what it was made of.
  bool get isComposed => parts.isNotEmpty;

  /// What the whole plate weighed, or null when it was not weighed.
  double? get totalGrams => parts.isEmpty
      ? null
      : parts.fold<double>(0, (sum, part) => sum + part.grams);

  FoodEntry copyWith({String? id}) => FoodEntry(
    id: id ?? this.id,
    date: date,
    name: name,
    portion: portion,
    macros: macros,
    meal: meal,
    parts: parts,
  );
}

/// One food inside a composed entry, with what it weighed.
///
/// Carries its own copy of the per-100 g figures rather than pointing at a
/// [Food]: correcting the database today must not rewrite what last week says
/// was eaten, which is the same rule the entry itself follows.
class FoodPart {
  FoodPart({
    required this.id,
    required String name,
    required this.grams,
    required this.per100g,
  }) : name = _validateName(name) {
    if (grams < 0) {
      throw ArgumentError.value(grams, 'grams', 'Must not be negative');
    }
  }

  final String id;
  final String name;

  /// What went on the scale.
  final double grams;

  /// What 100 g of it was made of, as it stood when this was logged.
  final Macros per100g;

  /// What this part contributed to the plate.
  Macros get macros => scaleMacros(per100g, grams);

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }
}

/// What a set of parts adds up to, and what the plate is made of per 100 g.
extension FoodPartsReading on List<FoodPart> {
  /// The sum of the parts.
  ///
  /// Each part is rounded to whole numbers as it is scaled, and the rounded
  /// figures are what is added. Summing the unrounded values and rounding
  /// once would be arithmetically tidier and would show a total that does not
  /// match the parts printed under it — and the user checks the sum by eye.
  Macros get total => fold(
    Macros.empty,
    (sum, part) => Macros(
      calories: sum.calories + part.macros.calories,
      protein: sum.protein + part.macros.protein,
      carbs: sum.carbs + part.macros.carbs,
      fat: sum.fat + part.macros.fat,
    ),
  );

  double get grams => fold<double>(0, (sum, part) => sum + part.grams);

  /// The whole plate quoted per 100 g, for saving it back as a food.
  ///
  /// Null when nothing was weighed: a composition with no weight has no
  /// reference to be quoted against, and dividing by zero grams would invent
  /// one.
  Macros? get per100g {
    final weight = grams;
    if (weight <= 0) return null;

    final sum = total;
    int at(int value) => (value * 100 / weight).round();

    return Macros(
      calories: at(sum.calories),
      protein: at(sum.protein),
      carbs: at(sum.carbs),
      fat: at(sum.fat),
    );
  }
}

/// An entry in the food database: what something is made of, per 100 g.
///
/// One reference weight for every food, so a figure can be scaled to whatever
/// was actually on the plate. Quoting macros against a free-text portion
/// instead — "1 plato" — makes them unscalable and, worse, unreadable: two
/// foods measured against two different plates cannot be compared, added, or
/// corrected. See [macrosFor] for the arithmetic that reference weight buys.
///
/// An entry does not point back at the food it came from, on purpose. What
/// was eaten is a record of a day, and correcting a food's figures today must
/// not rewrite what last week says. Picking a food copies its figures; from
/// then on the two are unrelated.
class Food {
  Food({
    required this.id,
    required String name,
    required this.per100g,
    this.isBuiltIn = false,
  }) : name = _validateName(name);

  /// The id of a food the database does not hold yet.
  ///
  /// It used to be zero, which worked while ids were counted from one. A
  /// UUID has no value that is obviously "none", so the absence is written
  /// down rather than encoded in a number: an empty id means the form is
  /// describing a food, not correcting a row.
  static const unsaved = '';

  final String id;
  final String name;

  /// What 100 g of it is made of. The unit is in the name because getting it
  /// wrong is silent: nothing about a bare `Macros` says which weight it is
  /// quoted for.
  final Macros per100g;

  /// Whether the app shipped this food or the user wrote it down.
  ///
  /// Not decoration: it is what lets a later reseed add foods without
  /// touching what the user typed, and it tells the picker which rows are the
  /// catalogue and which are theirs.
  final bool isBuiltIn;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  /// What [grams] of this food adds up to.
  Macros macrosFor(double grams) => scaleMacros(per100g, grams);

  Food copyWith({String? id, String? name, Macros? per100g}) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    per100g: per100g ?? this.per100g,
    isBuiltIn: isBuiltIn,
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

  /// The day split into its meals, in the order the day happens.
  ///
  /// A meal nothing was eaten at is absent rather than empty: the screen
  /// prints a heading per key, and four headings over three empty lists
  /// describe a form to fill in, not a day that was lived.
  Map<Meal, List<FoodEntry>> get byMeal {
    final grouped = <Meal, List<FoodEntry>>{};
    for (final meal in Meal.values) {
      final ofMeal = entries.where((e) => e.meal == meal).toList();
      if (ofMeal.isNotEmpty) grouped[meal] = ofMeal;
    }

    return grouped;
  }

  /// What was eaten without saying when. Everything logged before the app
  /// asked lands here, and it still counts towards [total].
  List<FoodEntry> get unassigned =>
      entries.where((e) => e.meal == null).toList();

  double get caloriesRatio => _ratio(total.calories, goal.calories);
  double get proteinRatio => _ratio(total.protein, goal.protein);
  double get carbsRatio => _ratio(total.carbs, goal.carbs);
  double get fatRatio => _ratio(total.fat, goal.fat);

  /// What is left of the day's energy budget. Negative once it is spent.
  int get caloriesRemaining => goal.calories - total.calories;

  static double _ratio(int value, int target) =>
      target <= 0 ? 0 : (value / target).clamp(0.0, 1.0);
}
