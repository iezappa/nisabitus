import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/database/uuid.dart';
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
  static const _goalId = singletonId;

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
            // An upsert replaces the row without going through
            // `writeTouched`, so the stamp is set here or it never moves.
            updatedAt: Value(DateTime.now()),
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
              ..orderBy([(e) => OrderingTerm.asc(e.rowId)]))
            .get();

    return _hydrate(rows);
  }

  @override
  Future<DailyNutrition> dayFor(DateTime day) async {
    final (entries, target) = await (entriesFor(day), goal()).wait;

    return DailyNutrition.from(entries, target);
  }

  @override
  Future<FoodEntry> addEntry(DateTime day, FoodDraft draft) =>
      _db.transaction(() => _addEntry(day, draft));

  Future<FoodEntry> _addEntry(DateTime day, FoodDraft draft) async {
    final date = dateOnly(day);
    // Building the entity first lets the domain reject a blank name before
    // anything is written.
    final validated = FoodEntry(
      id: newUuid(),
      date: date,
      name: draft.name,
      portion: draft.portion,
      macros: draft.macros,
      meal: draft.meal,
    );

    await _db
        .into(_db.foodEntries)
        .insert(
          FoodEntriesCompanion.insert(
            id: Value(validated.id),
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

    await _writeParts(validated.id, draft.parts);

    // Nothing is filed in the food database here. An entry's macros are for
    // whatever was on the plate, and there is no honest way back from those
    // to the per-100 g figure a food is quoted in unless the weight is known.
    // Saving a composition as a reusable dish is a separate, deliberate act —
    // the form offers it, and it goes through `saveFood` like anything else.

    return (await _entryById(validated.id))!;
  }

  @override
  Future<FoodEntry> updateEntry(String id, FoodDraft draft) =>
      _db.transaction(() => _updateEntry(id, draft));

  Future<FoodEntry> _updateEntry(String id, FoodDraft draft) async {
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

    await (_db.update(
      _db.foodEntries,
    )..where((e) => e.id.equals(id))).writeTouched(
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
    await _writeParts(id, draft.parts);

    return (await _entryById(id))!;
  }

  /// One entry with its parts attached.
  Future<FoodEntry?> _entryById(String id) async {
    final row = await (_db.select(
      _db.foodEntries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return null;

    return (await _hydrate([row])).single;
  }

  /// Attaches each entry's parts, in one query rather than one per entry.
  ///
  /// A day is a handful of entries and a month is a few hundred, so this is
  /// two reads instead of N+1 — and the stats window asks for a month at a
  /// time.
  Future<List<FoodEntry>> _hydrate(List<FoodEntryRow> rows) async {
    if (rows.isEmpty) return const [];

    final ids = {for (final row in rows) row.id};
    final parts =
        await (_db.select(_db.foodEntryItems)
              ..where((i) => i.entryId.isIn(ids))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();

    final byEntry = <String, List<FoodPart>>{};
    for (final part in parts) {
      (byEntry[part.entryId] ??= []).add(_toPart(part));
    }

    return [
      for (final row in rows)
        _toDomain(row, parts: byEntry[row.id] ?? const []),
    ];
  }

  FoodPart _toPart(FoodEntryItemRow row) => FoodPart(
    id: row.id,
    name: row.name,
    grams: row.grams,
    per100g: Macros(
      calories: row.caloriesPer100g,
      protein: row.proteinPer100g,
      carbs: row.carbsPer100g,
      fat: row.fatPer100g,
    ),
  );

  /// Replaces an entry's parts with the draft's.
  ///
  /// Written whole rather than diffed: the parts are a description of one
  /// plate, and there is no sense in which a part survives an edit that
  /// removed the food it described.
  Future<void> _writeParts(String entryId, List<FoodPartDraft> parts) async {
    await (_db.delete(
      _db.foodEntryItems,
    )..where((i) => i.entryId.equals(entryId))).go();

    for (final (index, part) in parts.indexed) {
      // Built first so a blank name or a negative weight is refused before
      // anything is written.
      final validated = FoodPart(
        id: newUuid(),
        name: part.name,
        grams: part.grams,
        per100g: part.per100g,
      );

      await _db
          .into(_db.foodEntryItems)
          .insert(
            FoodEntryItemsCompanion.insert(
              id: Value(validated.id),
              entryId: entryId,
              name: validated.name,
              grams: validated.grams,
              caloriesPer100g: Value(validated.per100g.calories),
              proteinPer100g: Value(validated.per100g.protein),
              carbsPer100g: Value(validated.per100g.carbs),
              fatPer100g: Value(validated.per100g.fat),
              position: index,
            ),
          );
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    await (_db.delete(_db.foodEntries)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<NutritionStats> statsFor(DateRange range) async {
    final rows = await (_db.select(
      _db.foodEntries,
    )..where((e) => e.date.isBetweenValues(range.start, range.end))).get();

    final (entries, target) = await (_hydrate(rows), goal()).wait;

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

    if (validated.id != Food.unsaved) {
      // A correction. `isBuiltIn` is left out on purpose: it records where the
      // row came from, and editing a shipped food does not make it the user's
      // invention any more than correcting a typo rewrites its history.
      await (_db.update(
        _db.foods,
      )..where((f) => f.id.equals(validated.id))).writeTouched(values);

      return validated;
    }

    // Upsert on the unique lower-case name, so writing down "avena" when
    // "Avena" is already there corrects that food rather than filing a second
    // one the picker would show twice.
    await _db
        .into(_db.foods)
        .insert(
          FoodsCompanion.insert(
            id: Value(newUuid()),
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

    // Read back rather than assumed: on a conflict the row that was already
    // there keeps its own id, and returning the one just minted would hand
    // the caller an id no row has.
    final stored = await (_db.select(
      _db.foods,
    )..where((f) => f.lowerName.equals(lowerName))).getSingle();

    return validated.copyWith(id: stored.id);
  }

  @override
  Future<void> deleteFood(String id) async {
    // Only the database row. What was eaten stays exactly as it was logged:
    // the entry copied its figures and never pointed back here.
    await (_db.delete(_db.foods)..where((f) => f.id.equals(id))).go();
  }

  FoodEntry _toDomain(FoodEntryRow row, {List<FoodPart> parts = const []}) =>
      FoodEntry(
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
        parts: parts,
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
