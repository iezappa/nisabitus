import 'package:drift/drift.dart';

/// The daily macronutrient targets.
///
/// A single row: there is one user and one set of goals. The id is pinned so
/// saving always replaces it rather than piling up revisions.
@DataClassName('NutritionGoalRow')
class NutritionGoals extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get calories => integer().withDefault(const Constant(2000))();
  IntColumn get protein => integer().withDefault(const Constant(120))();
  IntColumn get carbs => integer().withDefault(const Constant(220))();
  IntColumn get fat => integer().withDefault(const Constant(70))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One thing eaten on one day.
@DataClassName('FoodEntryRow')
@TableIndex(name: 'food_entry_by_day', columns: {#date})
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Free text, so "150 g", "1 plato" and "2 unidades" all fit.
  TextColumn get portion => text().withLength(max: 255).nullable()();

  IntColumn get calories => integer().withDefault(const Constant(0))();
  IntColumn get protein => integer().withDefault(const Constant(0))();
  IntColumn get carbs => integer().withDefault(const Constant(0))();
  IntColumn get fat => integer().withDefault(const Constant(0))();

  /// Which meal of the day this belonged to, as `Meal.wireName`.
  ///
  /// Nullable, and null is not a default: every entry written before the app
  /// asked has no answer, and stamping them with a meal would put food on
  /// the record at an hour nobody ate it.
  TextColumn get meal => text().withLength(max: 16).nullable()();
}

/// The food database: what things are made of, per 100 g.
///
/// A reference table, seeded with what is actually eaten in Argentina and
/// added to by hand. Every figure is quoted against the same weight, which is
/// the whole point: 100 g is a fixed reference, so any portion can be worked
/// out from it, and two foods can be compared. The previous shape quoted
/// macros against a free-text portion ("1 plato") and could do neither.
///
/// Deliberately not linked to [FoodEntries] — an entry copies these figures
/// once and never looks back, so correcting a food today cannot rewrite what
/// last week says was eaten.
@DataClassName('FoodRow')
@TableIndex(name: 'food_by_name', columns: {#lowerName}, unique: true)
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// The name folded to lower case, so the uniqueness above is the question
  /// the app actually asks: eating "avena" after "Avena" is the same food
  /// twice, not a second one. SQLite's own `COLLATE NOCASE` only folds
  /// ASCII, which would file "Ñoquis" and "ñoquis" separately — in Spanish
  /// copy that is not an edge case.
  TextColumn get lowerName => text().withLength(min: 1, max: 255)();

  /// What 100 g of it is made of. The unit is in every column name because a
  /// figure that is silently quoted for the wrong weight is off by a factor
  /// nobody notices — `calories` alone never said which portion it meant.
  IntColumn get caloriesPer100g => integer().withDefault(const Constant(0))();
  IntColumn get proteinPer100g => integer().withDefault(const Constant(0))();
  IntColumn get carbsPer100g => integer().withDefault(const Constant(0))();
  IntColumn get fatPer100g => integer().withDefault(const Constant(0))();

  /// Whether the app shipped this food or the user wrote it down.
  ///
  /// It is what lets a later reseed add foods without touching what the user
  /// typed, and it is what tells the picker whose row it is showing.
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  // `portion` and `lastUsedAt` are both gone as of v13.
  //
  // `portion` was the weight these macros were quoted for, and there is only
  // one now: 100 g, named in every column. Keeping a free-text portion here
  // would let a row claim its figures were for something else, which is the
  // exact ambiguity the reshape removes. The entry still has one, because
  // what was on the plate is a fact about the meal, not about the food.
  //
  // `lastUsedAt` ordered the old list by what had been eaten lately, which
  // worked while the catalogue was a short list the user had built by eating.
  // It is a reference table of eighty-odd foods now, and it is read by
  // searching for a name — so it is ordered by name, and "recently used"
  // would only bury the seed under whatever was logged this morning.
}
