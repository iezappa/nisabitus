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

/// A food worth not typing again.
///
/// Filled by using the app rather than by maintaining it: saving an entry
/// files what it describes here. Deliberately not linked to [FoodEntries] —
/// an entry copies these figures once and never looks back, so correcting a
/// food today cannot rewrite what last week says was eaten.
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

  TextColumn get portion => text().withLength(max: 255).nullable()();

  IntColumn get calories => integer().withDefault(const Constant(0))();
  IntColumn get protein => integer().withDefault(const Constant(0))();
  IntColumn get carbs => integer().withDefault(const Constant(0))();
  IntColumn get fat => integer().withDefault(const Constant(0))();

  /// When it was last eaten, which is the order the picker shows.
  DateTimeColumn get lastUsedAt => dateTime()();
}
