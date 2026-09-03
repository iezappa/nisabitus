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

    // Saving is what fills the catalogue. Only on the way in, not on an
    // edit: correcting a typo would otherwise leave the typo behind as a
    // food of its own, and the picker would slowly fill with mistakes.
    await rememberFood(validated.toFood(), eatenOn: date);

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
              (f) => OrderingTerm.desc(f.lastUsedAt),
              // Two foods eaten on the same day still need an order, and
              // without one the list reshuffles between reads.
              (f) => OrderingTerm.desc(f.id),
            ]))
            .get();

    return rows.map(_foodToDomain).toList();
  }

  @override
  Future<Food> rememberFood(Food food, {DateTime? eatenOn}) async {
    // Building the entity first lets the domain reject a blank name before
    // anything is written.
    final validated = Food(
      id: food.id,
      name: food.name,
      portion: food.portion,
      macros: food.macros,
    );
    final lowerName = validated.name.toLowerCase();
    final eaten = dateOnly(eatenOn ?? DateTime.now());

    // Read first, so filling in a meal from last week does not push that
    // food to the top of a list whose whole job is "what you eat lately".
    // The later of the two dates wins, and it is worked out here rather than
    // in the upsert because the conflict clause cannot see the old row.
    final existing = await (_db.select(
      _db.foods,
    )..where((f) => f.lowerName.equals(lowerName))).getSingleOrNull();

    final lastUsedAt = existing == null || eaten.isAfter(existing.lastUsedAt)
        ? eaten
        : existing.lastUsedAt;

    // Upsert on the unique lower-case name, so eating the same thing again
    // updates the food rather than filing a second one. The newest spelling
    // and figures win: what was typed last is what the user means today.
    final id = await _db
        .into(_db.foods)
        .insert(
          FoodsCompanion.insert(
            name: validated.name,
            lowerName: lowerName,
            portion: Value(validated.portion),
            calories: Value(validated.macros.calories),
            protein: Value(validated.macros.protein),
            carbs: Value(validated.macros.carbs),
            fat: Value(validated.macros.fat),
            lastUsedAt: lastUsedAt,
          ),
          onConflict: DoUpdate(
            (_) => FoodsCompanion(
              name: Value(validated.name),
              portion: Value(validated.portion),
              calories: Value(validated.macros.calories),
              protein: Value(validated.macros.protein),
              carbs: Value(validated.macros.carbs),
              fat: Value(validated.macros.fat),
              lastUsedAt: Value(lastUsedAt),
            ),
            target: [_db.foods.lowerName],
          ),
        );

    return validated.copyWith(id: id);
  }

  @override
  Future<void> forgetFood(int id) async {
    // Only the catalogue row. What was eaten stays exactly as it was logged.
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
    portion: row.portion,
    macros: Macros(
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
    ),
  );
}
