import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_repository.dart';
import '../domain/nutrition_stats.dart';

/// Drift-backed implementation of [NutritionRepository].
class DriftNutritionRepository implements NutritionRepository {
  DriftNutritionRepository(this._db);

  final AppDatabase _db;

  /// The goals live in a single pinned row.
  static const _goalId = 1;

  @override
  Future<NutritionGoal> goal() async {
    final row = await (_db.select(
      _db.nutritionGoals,
    )..where((g) => g.id.equals(_goalId))).getSingleOrNull();

    if (row == null) return NutritionGoal.fallback;

    return NutritionGoal(
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
    );
  }

  @override
  Future<NutritionGoal> saveGoal(NutritionGoal goal) async {
    await _db
        .into(_db.nutritionGoals)
        .insertOnConflictUpdate(
          NutritionGoalsCompanion.insert(
            id: const Value(_goalId),
            calories: Value(goal.calories),
            protein: Value(goal.protein),
            carbs: Value(goal.carbs),
            fat: Value(goal.fat),
          ),
        );

    return goal;
  }

  @override
  Future<List<FoodEntry>> entriesFor(DateTime day) async {
    final rows =
        await (_db.select(_db.foodEntries)
              ..where((e) => e.date.equals(dateOnly(day)))
              ..orderBy([(e) => OrderingTerm.asc(e.id)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<DailyNutrition> dayFor(DateTime day) async {
    final (entries, target) = await (entriesFor(day), goal()).wait;

    return DailyNutrition.from(entries, target);
  }

  @override
  Future<FoodEntry> addEntry(DateTime day, FoodDraft draft) async {
    final date = dateOnly(day);
    // Building the entity first lets the domain reject a blank name before
    // anything is written.
    final validated = FoodEntry(
      id: 0,
      date: date,
      name: draft.name,
      portion: draft.portion,
      macros: draft.macros,
      meal: draft.meal,
    );

    final id = await _db
        .into(_db.foodEntries)
        .insert(
          FoodEntriesCompanion.insert(
            date: date,
            name: validated.name,
            portion: Value(validated.portion),
            calories: Value(validated.macros.calories),
            protein: Value(validated.macros.protein),
            carbs: Value(validated.macros.carbs),
            fat: Value(validated.macros.fat),
            meal: Value(validated.meal?.wireName),
          ),
        );

    // Nothing is filed in the food database here any more. An entry's macros
    // are for whatever was on the plate, and there is no honest way back from
    // those to the per-100 g figure a food is quoted in — the weight they
    // were measured against is not recorded. The database is seeded and added
    // to on purpose instead.

    return validated.copyWith(id: id);
  }

  @override
  Future<FoodEntry> updateEntry(int id, FoodDraft draft) async {
    final existing = await (_db.select(
      _db.foodEntries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (existing == null) throw StateError('Food entry $id was not found');

    final validated = FoodEntry(
      id: id,
      date: existing.date,
      name: draft.name,
      portion: draft.portion,
      macros: draft.macros,
      meal: draft.meal,
    );

    await (_db.update(_db.foodEntries)..where((e) => e.id.equals(id))).write(
      FoodEntriesCompanion(
        name: Value(validated.name),
        portion: Value(validated.portion),
        calories: Value(validated.macros.calories),
        protein: Value(validated.macros.protein),
        carbs: Value(validated.macros.carbs),
        fat: Value(validated.macros.fat),
        // Written as an absent-or-null value rather than skipped: taking the
        // meal off an entry is a thing to be able to do, and a companion
        // that leaves the field out cannot say it.
        meal: Value(validated.meal?.wireName),
      ),
    );

    return validated;
  }

  @override
  Future<void> deleteEntry(int id) async {
    await (_db.delete(_db.foodEntries)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<NutritionStats> statsFor(DateRange range) async {
    final rows = await (_db.select(
      _db.foodEntries,
    )..where((e) => e.date.isBetweenValues(range.start, range.end))).get();

    final (entries, target) = (rows.map(_toDomain).toList(), await goal());

    return NutritionStats.from(range, entries, target);
  }

  @override
  Future<List<Food>> foods() async {
    final rows =
        await (_db.select(_db.foods)..orderBy([
              // By the folded name, so "Ñoquis" sorts where a reader looks for
              // it rather than after "Zapallo" the way raw code points would
              // put it.
              (f) => OrderingTerm.asc(f.lowerName),
            ]))
            .get();

    return rows.map(_foodToDomain).toList();
  }

  @override
  Future<Food> saveFood(Food food) async {
    // Building the entity first lets the domain reject a blank name before
    // anything is written.
    final validated = Food(
      id: food.id,
      name: food.name,
      per100g: food.per100g,
      isBuiltIn: food.isBuiltIn,
    );
    final lowerName = validated.name.toLowerCase();

    final values = FoodsCompanion(
      name: Value(validated.name),
      lowerName: Value(lowerName),
      caloriesPer100g: Value(validated.per100g.calories),
      proteinPer100g: Value(validated.per100g.protein),
      carbsPer100g: Value(validated.per100g.carbs),
      fatPer100g: Value(validated.per100g.fat),
    );

    if (validated.id != 0) {
      // A correction. `isBuiltIn` is left out on purpose: it records where the
      // row came from, and editing a shipped food does not make it the user's
      // invention any more than correcting a typo rewrites its history.
      await (_db.update(
        _db.foods,
      )..where((f) => f.id.equals(validated.id))).write(values);

      return validated;
    }

    // Upsert on the unique lower-case name, so writing down "avena" when
    // "Avena" is already there corrects that food rather than filing a second
    // one the picker would show twice.
    final id = await _db
        .into(_db.foods)
        .insert(
          FoodsCompanion.insert(
            name: validated.name,
            lowerName: lowerName,
            caloriesPer100g: Value(validated.per100g.calories),
            proteinPer100g: Value(validated.per100g.protein),
            carbsPer100g: Value(validated.per100g.carbs),
            fatPer100g: Value(validated.per100g.fat),
            isBuiltIn: Value(validated.isBuiltIn),
          ),
          onConflict: DoUpdate((_) => values, target: [_db.foods.lowerName]),
        );

    return validated.copyWith(id: id);
  }

  @override
  Future<void> deleteFood(int id) async {
    // Only the database row. What was eaten stays exactly as it was logged:
    // the entry copied its figures and never pointed back here.
    await (_db.delete(_db.foods)..where((f) => f.id.equals(id))).go();
  }

  FoodEntry _toDomain(FoodEntryRow row) => FoodEntry(
    id: row.id,
    date: row.date,
    name: row.name,
    portion: row.portion,
    macros: Macros(
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
    ),
    meal: Meal.parse(row.meal),
  );

  Food _foodToDomain(FoodRow row) => Food(
    id: row.id,
    name: row.name,
    per100g: Macros(
      calories: row.caloriesPer100g,
      protein: row.proteinPer100g,
      carbs: row.carbsPer100g,
      fat: row.fatPer100g,
    ),
    isBuiltIn: row.isBuiltIn,
  );
}
