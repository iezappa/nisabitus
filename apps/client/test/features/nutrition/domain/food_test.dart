import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';

void main() {
  group('Food', () {
    test('keeps the name it was given, trimmed', () {
      final food = Food(
        id: 1,
        name: '  Avena  ',
        macros: const Macros(calories: 300),
      );

      expect(food.name, 'Avena');
    });

    test('refuses a blank name', () {
      expect(
        () => Food(id: 1, name: '   ', macros: Macros.empty),
        throwsArgumentError,
      );
    });

    test('describes an entry it could fill in', () {
      final food = Food(
        id: 7,
        name: 'Avena',
        portion: '80 g',
        macros: const Macros(calories: 300, protein: 10),
      );

      final draft = food.toDraft(meal: Meal.breakfast);

      expect(draft.name, 'Avena');
      expect(draft.portion, '80 g');
      expect(draft.macros, const Macros(calories: 300, protein: 10));
      expect(draft.meal, Meal.breakfast);
    });
  });

  group('FoodEntry', () {
    test('remembers which meal it belonged to', () {
      final entry = FoodEntry(
        id: 1,
        date: DateTime(2026, 3, 11),
        name: 'Avena',
        macros: Macros.empty,
        meal: Meal.breakfast,
      );

      expect(entry.meal, Meal.breakfast);
    });

    test('accepts having no meal at all', () {
      // Every entry written before the app asked. They are not broken and
      // they are not breakfast.
      final entry = FoodEntry(
        id: 1,
        date: DateTime(2026, 3, 11),
        name: 'Avena',
        macros: Macros.empty,
      );

      expect(entry.meal, isNull);
    });

    test('carries the meal through a copy', () {
      final entry = FoodEntry(
        id: 0,
        date: DateTime(2026, 3, 11),
        name: 'Avena',
        macros: Macros.empty,
        meal: Meal.lunch,
      );

      expect(entry.copyWith(id: 9).meal, Meal.lunch);
    });

    test('offers itself back to the catalogue as a food', () {
      // Saving an entry is what fills the catalogue: nobody maintains a list
      // of foods by hand, or the list stays empty.
      final entry = FoodEntry(
        id: 3,
        date: DateTime(2026, 3, 11),
        name: 'Avena',
        portion: '80 g',
        macros: const Macros(calories: 300),
        meal: Meal.breakfast,
      );

      final food = entry.toFood();

      expect(food.name, 'Avena');
      expect(food.portion, '80 g');
      expect(food.macros, const Macros(calories: 300));
    });
  });

  group('DailyNutrition', () {
    FoodEntry at(Meal? meal, String name) => FoodEntry(
      id: name.hashCode,
      date: DateTime(2026, 3, 11),
      name: name,
      macros: const Macros(calories: 100),
      meal: meal,
    );

    test('groups the day by meal, in the order the day happens', () {
      final day = DailyNutrition.from([
        at(Meal.dinner, 'Sopa'),
        at(Meal.breakfast, 'Avena'),
        at(Meal.lunch, 'Pollo'),
      ], NutritionGoal.fallback);

      expect(day.byMeal.keys, [Meal.breakfast, Meal.lunch, Meal.dinner]);
      expect(day.byMeal[Meal.breakfast]!.single.name, 'Avena');
    });

    test('leaves out a meal nothing was eaten at', () {
      final day = DailyNutrition.from([
        at(Meal.lunch, 'Pollo'),
      ], NutritionGoal.fallback);

      expect(day.byMeal.keys, [Meal.lunch]);
    });

    test(
      'keeps the entries with no meal apart from the ones that have one',
      () {
        final day = DailyNutrition.from([
          at(null, 'Algo'),
          at(Meal.lunch, 'Pollo'),
        ], NutritionGoal.fallback);

        expect(day.byMeal.keys, [Meal.lunch]);
        expect(day.unassigned.single.name, 'Algo');
      },
    );

    test('still totals everything, meal or no meal', () {
      final day = DailyNutrition.from([
        at(null, 'Algo'),
        at(Meal.lunch, 'Pollo'),
      ], NutritionGoal.fallback);

      expect(day.total.calories, 200);
    });
  });
}
