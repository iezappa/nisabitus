import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_repository.dart';

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
          ),
        );

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
    );

    await (_db.update(_db.foodEntries)..where((e) => e.id.equals(id))).write(
      FoodEntriesCompanion(
        name: Value(validated.name),
        portion: Value(validated.portion),
        calories: Value(validated.macros.calories),
        protein: Value(validated.macros.protein),
        carbs: Value(validated.macros.carbs),
        fat: Value(validated.macros.fat),
      ),
    );

    return validated;
  }

  @override
  Future<void> deleteEntry(int id) async {
    await (_db.delete(_db.foodEntries)..where((e) => e.id.equals(id))).go();
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
  );
}
