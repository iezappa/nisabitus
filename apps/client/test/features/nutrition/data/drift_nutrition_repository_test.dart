import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/nutrition/data/drift_nutrition_repository.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition_repository.dart';

void main() {
  late AppDatabase db;
  late NutritionRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftNutritionRepository(db);
  });
  tearDown(() => db.close());

  FoodDraft draft({
    String name = 'Avena',
    int kcal = 300,
    int p = 10,
    int c = 50,
    int f = 5,
    String? portion,
    Meal? meal,
  }) => FoodDraft(
    name: name,
    portion: portion,
    macros: Macros(calories: kcal, protein: p, carbs: c, fat: f),
    meal: meal,
  );

  group('goals', () {
    test('start on a sensible default rather than zero', () async {
      final goal = await repository.goal();

      expect(goal.isUnset, isFalse);
      expect(goal.calories, NutritionGoal.fallback.calories);
    });

    test('are remembered once saved', () async {
      await repository.saveGoal(
        NutritionGoal(calories: 2400, protein: 160, carbs: 250, fat: 80),
      );

      expect((await repository.goal()).protein, 160);
    });

    test('replace the previous ones instead of piling up', () async {
      await repository.saveGoal(
        NutritionGoal(calories: 2400, protein: 160, carbs: 250, fat: 80),
      );
      await repository.saveGoal(
        NutritionGoal(calories: 1800, protein: 140, carbs: 180, fat: 60),
      );

      expect((await repository.goal()).calories, 1800);
      expect(await db.select(db.nutritionGoals).get(), hasLength(1));
    });

    test('reject an absurd target', () {
      expect(
        () => NutritionGoal(calories: 99999, protein: 0, carbs: 0, fat: 0),
        throwsArgumentError,
      );
    });
  });

  group('entries', () {
    test('belong to the day they were logged on', () async {
      await repository.addEntry(monday, draft(name: 'Lunes'));
      await repository.addEntry(tuesday, draft(name: 'Martes'));

      expect((await repository.entriesFor(monday)).map((e) => e.name), [
        'Lunes',
      ]);
    });

    test('keep the order they were logged in', () async {
      await repository.addEntry(monday, draft(name: 'Desayuno'));
      await repository.addEntry(monday, draft(name: 'Almuerzo'));
      await repository.addEntry(monday, draft(name: 'Cena'));

      expect((await repository.entriesFor(monday)).map((e) => e.name), [
        'Desayuno',
        'Almuerzo',
        'Cena',
      ]);
    });

    test('reject a blank name', () {
      expect(
        () => repository.addEntry(monday, draft(name: '  ')),
        throwsArgumentError,
      );
    });

    test('keep a free-text portion', () async {
      await repository.addEntry(monday, draft(portion: '150 g'));

      expect((await repository.entriesFor(monday)).single.portion, '150 g');
    });

    test('can be edited without moving day', () async {
      final entry = await repository.addEntry(monday, draft());

      await repository.updateEntry(
        entry.id,
        draft(name: 'Avena con fruta', kcal: 380),
      );

      final stored = (await repository.entriesFor(monday)).single;
      expect(stored.name, 'Avena con fruta');
      expect(stored.macros.calories, 380);
      expect(stored.date, monday);
    });

    test('can be removed', () async {
      final entry = await repository.addEntry(monday, draft());

      await repository.deleteEntry(entry.id);

      expect(await repository.entriesFor(monday), isEmpty);
    });
  });

  group('the day', () {
    test('is empty before anything is logged', () async {
      final day = await repository.dayFor(monday);

      expect(day.isEmpty, isTrue);
      expect(day.total, Macros.empty);
    });

    test('totals the entries against the saved targets', () async {
      await repository.saveGoal(
        NutritionGoal(calories: 2000, protein: 100, carbs: 200, fat: 60),
      );
      await repository.addEntry(monday, draft(kcal: 600, p: 30, c: 80, f: 20));
      await repository.addEntry(monday, draft(kcal: 400, p: 20, c: 20, f: 10));

      final day = await repository.dayFor(monday);

      expect(day.total.calories, 1000);
      expect(day.caloriesRatio, 0.5);
      expect(day.caloriesRemaining, 1000);
      expect(day.goal.protein, 100);
    });

    test('does not count another day towards it', () async {
      await repository.addEntry(tuesday, draft(kcal: 900));

      expect((await repository.dayFor(monday)).total.calories, 0);
    });
  });

  group('statsFor', () {
    test('reads the window as empty before anything is logged', () async {
      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.isEmpty, isTrue);
    });

    test('adds up the energy of the window and leaves the rest out', () async {
      await repository.addEntry(monday, draft(kcal: 500));
      await repository.addEntry(tuesday, draft(kcal: 700));
      await repository.addEntry(DateTime(2026, 3, 20), draft(kcal: 900));

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.totalCalories, 1200);
      expect(stats.daysLogged, 2);
      expect(stats.perDay, hasLength(2));
    });

    test('carries the saved goal, not the fallback', () async {
      await repository.saveGoal(
        NutritionGoal(calories: 2400, protein: 160, carbs: 250, fat: 80),
      );

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.goalCalories, 2400);
    });
  });

  group('meals', () {
    test('stores which meal an entry belonged to', () async {
      await repository.addEntry(monday, draft(meal: Meal.breakfast));

      final stored = (await repository.entriesFor(monday)).single;
      expect(stored.meal, Meal.breakfast);
    });

    test('accepts an entry that names no meal', () async {
      await repository.addEntry(monday, draft());

      expect((await repository.entriesFor(monday)).single.meal, isNull);
    });

    test('changes the meal an entry is filed under', () async {
      final entry = await repository.addEntry(
        monday,
        draft(meal: Meal.breakfast),
      );

      await repository.updateEntry(entry.id, draft(meal: Meal.dinner));

      expect((await repository.entriesFor(monday)).single.meal, Meal.dinner);
    });

    test('takes the meal off an entry that had one', () async {
      // Not the same as leaving it alone: someone who no longer knows which
      // meal it was has to be able to say so.
      final entry = await repository.addEntry(
        monday,
        draft(meal: Meal.breakfast),
      );

      await repository.updateEntry(entry.id, draft());

      expect((await repository.entriesFor(monday)).single.meal, isNull);
    });

    test('groups the day it reads back', () async {
      await repository.addEntry(
        monday,
        draft(name: 'Avena', meal: Meal.breakfast),
      );
      await repository.addEntry(monday, draft(name: 'Pollo', meal: Meal.lunch));

      final day = await repository.dayFor(monday);

      expect(day.byMeal[Meal.breakfast]!.single.name, 'Avena');
      expect(day.byMeal[Meal.lunch]!.single.name, 'Pollo');
    });
  });

  group('the food database', () {
    test('ships with the foods the app seeds', () async {
      // A database that starts empty is a database nobody uses: the point of
      // the reshape is that picking a food is possible on the first day.
      final foods = await repository.foods();

      expect(foods, isNotEmpty);
      expect(foods.map((f) => f.name), contains('Milanesa de carne'));
      expect(foods.every((f) => f.isBuiltIn), isTrue);
    });

    test('quotes what it ships per one hundred grams', () async {
      final avena = (await repository.foods()).firstWhere(
        (f) => f.name == 'Avena',
      );

      expect(avena.per100g.calories, 380);
      expect(avena.macrosFor(50).calories, 190);
    });

    test('lists foods by name, so a long list can be read', () async {
      final names = (await repository.foods()).map((f) => f.name).toList();

      expect(names, orderedEquals(List.of(names)..sort()));
    });

    test('does not file a food from an entry that was saved', () async {
      // The old catalogue filled itself from what was logged. It cannot any
      // more: an entry's macros are for whatever was on the plate, and there
      // is no way back from those to a per-100 g figure.
      final before = (await repository.foods()).length;

      await repository.addEntry(monday, draft(name: 'Algo que nadie pesó'));

      expect(await repository.foods(), hasLength(before));
    });

    test('writes down a food of the user own', () async {
      final saved = await repository.saveFood(
        Food(
          id: 0,
          name: 'Licuado de banana',
          per100g: const Macros(calories: 90, protein: 2, carbs: 18, fat: 1),
        ),
      );

      expect(saved.id, isNonZero);
      expect(saved.isBuiltIn, isFalse);

      final stored = (await repository.foods()).firstWhere(
        (f) => f.name == 'Licuado de banana',
      );
      expect(stored.per100g.calories, 90);
      expect(stored.isBuiltIn, isFalse);
    });

    test('files the same food once however it was capitalised', () async {
      await repository.saveFood(
        Food(id: 0, name: 'Ñoquis caseros', per100g: Macros.empty),
      );
      await repository.saveFood(
        Food(id: 0, name: 'ñoquis caseros', per100g: Macros.empty),
      );

      final matches = (await repository.foods()).where(
        (f) => f.name.toLowerCase() == 'ñoquis caseros',
      );
      expect(matches, hasLength(1));
    });

    test('corrects a food it already had', () async {
      final saved = await repository.saveFood(
        Food(id: 0, name: 'Licuado', per100g: const Macros(calories: 90)),
      );

      await repository.saveFood(
        saved.copyWith(
          name: 'Licuado de banana',
          per100g: const Macros(calories: 95),
        ),
      );

      final stored = (await repository.foods()).firstWhere(
        (f) => f.id == saved.id,
      );
      expect(stored.name, 'Licuado de banana');
      expect(stored.per100g.calories, 95);
    });

    test('deletes a food without rewriting what was eaten', () async {
      // The database is a reference. Deleting from it must not rewrite the
      // record of a day that was actually lived.
      final saved = await repository.saveFood(
        Food(id: 0, name: 'Licuado', per100g: const Macros(calories: 90)),
      );
      await repository.addEntry(monday, draft(name: 'Licuado', kcal: 135));

      await repository.deleteFood(saved.id);

      expect(
        (await repository.foods()).where((f) => f.id == saved.id),
        isEmpty,
      );
      final entry = (await repository.entriesFor(monday)).single;
      expect(entry.name, 'Licuado');
      expect(entry.macros.calories, 135);
    });

    test('does not rewrite what was eaten when a food is corrected', () async {
      // The whole reason an entry holds no reference to its food: last week
      // says what was eaten last week, whatever the database says today.
      final saved = await repository.saveFood(
        Food(id: 0, name: 'Avena casera', per100g: const Macros(calories: 380)),
      );
      await repository.addEntry(monday, draft(name: 'Avena casera', kcal: 300));

      await repository.saveFood(
        saved.copyWith(per100g: const Macros(calories: 999)),
      );

      expect((await repository.entriesFor(monday)).single.macros.calories, 300);
    });
  });
}
