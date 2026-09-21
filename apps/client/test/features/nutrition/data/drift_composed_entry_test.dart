import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/nutrition/data/drift_nutrition_repository.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition_repository.dart';

void main() {
  late AppDatabase db;
  late NutritionRepository repository;
  final monday = DateTime(2026, 3, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftNutritionRepository(db);
  });
  tearDown(() => db.close());

  const chicken = Macros(calories: 165, protein: 31, carbs: 0, fat: 4);
  const rice = Macros(calories: 130, protein: 3, carbs: 28, fat: 0);

  FoodDraft lunch() => const FoodDraft(
    name: 'Pollo + Arroz',
    macros: Macros(calories: 508, protein: 53, carbs: 56, fat: 6),
    parts: [
      FoodPartDraft(name: 'Pollo', grams: 150, per100g: chicken),
      FoodPartDraft(name: 'Arroz', grams: 200, per100g: rice),
    ],
  );

  test('an entry comes back with what it was made of', () async {
    await repository.addEntry(monday, lunch());

    final entry = (await repository.entriesFor(monday)).single;
    expect(entry.isComposed, isTrue);
    expect(entry.parts.map((part) => part.name), ['Pollo', 'Arroz']);
    expect(entry.parts.first.grams, 150);
    expect(entry.totalGrams, 350);
  });

  test('the parts keep the order they were added in', () async {
    await repository.addEntry(monday, lunch());

    expect(
      (await repository.entriesFor(monday)).single.parts.last.name,
      'Arroz',
    );
  });

  test('the stored total is what the entry is worth', () async {
    // The parts explain the total; they do not replace it. Everything that
    // already asks an entry what it was worth keeps working.
    await repository.addEntry(monday, lunch());

    expect((await repository.entriesFor(monday)).single.macros.calories, 508);
  });

  test('a part does not follow a correction to the food database', () async {
    // The rule the whole module rests on: what was eaten is a record of a
    // day, and correcting a food today must not rewrite last Tuesday.
    final food = await repository.saveFood(
      Food(id: Food.unsaved, name: 'Pollo', per100g: chicken),
    );
    await repository.addEntry(monday, lunch());

    await repository.saveFood(
      food.copyWith(per100g: const Macros(calories: 999)),
    );

    final part = (await repository.entriesFor(monday)).single.parts
        .firstWhere((part) => part.name == 'Pollo');
    expect(part.per100g.calories, 165);
  });

  test(
    'editing an entry replaces its parts rather than adding to them',
    () async {
      final entry = await repository.addEntry(monday, lunch());

      final edited = await repository.updateEntry(
        entry.id,
        const FoodDraft(
          name: 'Solo arroz',
          macros: Macros(calories: 260),
          parts: [FoodPartDraft(name: 'Arroz', grams: 200, per100g: rice)],
        ),
      );

      expect(edited.parts.map((part) => part.name), ['Arroz']);
      expect(await db.select(db.foodEntryItems).get(), hasLength(1));
    },
  );

  test('an entry typed whole has no parts and is not a special case', () async {
    await repository.addEntry(
      monday,
      const FoodDraft(name: 'Café', macros: Macros(calories: 5)),
    );

    final entry = (await repository.entriesFor(monday)).single;
    expect(entry.isComposed, isFalse);
    expect(entry.macros.calories, 5);
  });

  test('deleting the entry takes its parts with it', () async {
    final entry = await repository.addEntry(monday, lunch());

    await repository.deleteEntry(entry.id);

    expect(await db.select(db.foodEntryItems).get(), isEmpty);
  });

  test('the day totals the composed entry like any other', () async {
    await repository.addEntry(monday, lunch());

    expect((await repository.dayFor(monday)).total.calories, 508);
  });
}
