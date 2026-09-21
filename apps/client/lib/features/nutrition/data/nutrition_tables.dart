import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// The daily macronutrient targets.
///
/// A single row: there is one user and one set of goals. The id is pinned so
/// saving always replaces it rather than piling up revisions.
@DataClassName('NutritionGoalRow')
class NutritionGoals extends Table with SingletonColumns {
  IntColumn get calories => integer().withDefault(const Constant(2000))();
  IntColumn get protein => integer().withDefault(const Constant(120))();
  IntColumn get carbs => integer().withDefault(const Constant(220))();
  IntColumn get fat => integer().withDefault(const Constant(70))();
}

/// One thing eaten on one day.
@DataClassName('FoodEntryRow')
@TableIndex(name: 'food_entry_by_day', columns: {#date})
class FoodEntries extends Table with RecordColumns {
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
class Foods extends Table with RecordColumns {
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

/// One food that went into a composed entry, with what it weighed.
///
/// A lunch is often two or three things — pollo con arroz — and the only way
/// to record that used to be one entry per ingredient or one entry with the
/// macros added up by hand. This table holds the parts, so the entry can be
/// read back as what it was made of rather than as a total nobody can check.
///
/// **The figures are copied, and there is no reference to [Foods].** That is
/// the rule the entry itself follows and for the same reason: what was eaten
/// is a record of a day, and correcting a food's composition today must not
/// rewrite what last Tuesday's lunch says it was.
///
/// The entry's own macro columns stay authoritative. These parts explain that
/// total; they do not replace it.
@DataClassName('FoodEntryItemRow')
@TableIndex(name: 'entry_item_by_entry', columns: {#entryId, #position})
class FoodEntryItems extends Table with RecordColumns {
  TextColumn get entryId =>
      text().references(FoodEntries, #id, onDelete: KeyAction.cascade)();

  /// The food's name as it was when this was logged.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// What went on the scale. Real rather than integer: half a gram matters
  /// for oil and for salt.
  RealColumn get grams => real()();

  /// What 100 g of it was made of, copied at the moment it was logged.
  IntColumn get caloriesPer100g => integer().withDefault(const Constant(0))();
  IntColumn get proteinPer100g => integer().withDefault(const Constant(0))();
  IntColumn get carbsPer100g => integer().withDefault(const Constant(0))();
  IntColumn get fatPer100g => integer().withDefault(const Constant(0))();

  /// The order they were added in, which is the order they read best.
  IntColumn get position => integer()();
}
