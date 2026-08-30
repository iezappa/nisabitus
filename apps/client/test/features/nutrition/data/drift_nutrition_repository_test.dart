import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/time/date_range.dart';
import 'package:nisabit/features/nutrition/data/drift_nutrition_repository.dart';
import 'package:nisabit/features/nutrition/domain/nutrition.dart';
import 'package:nisabit/features/nutrition/domain/nutrition_repository.dart';

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
  }) => FoodDraft(
    name: name,
    portion: portion,
    macros: Macros(calories: kcal, protein: p, carbs: c, fat: f),
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

      expect(
        (await repository.entriesFor(monday)).map((e) => e.name),
        ['Lunes'],
      );
    });

    test('keep the order they were logged in', () async {
      await repository.addEntry(monday, draft(name: 'Desayuno'));
      await repository.addEntry(monday, draft(name: 'Almuerzo'));
      await repository.addEntry(monday, draft(name: 'Cena'));

      expect(
        (await repository.entriesFor(monday)).map((e) => e.name),
        ['Desayuno', 'Almuerzo', 'Cena'],
      );
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

      await repository.updateEntry(entry.id, draft(name: 'Avena con fruta', kcal: 380));

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
}
