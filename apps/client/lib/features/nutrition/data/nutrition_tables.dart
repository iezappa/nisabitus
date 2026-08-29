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
}
