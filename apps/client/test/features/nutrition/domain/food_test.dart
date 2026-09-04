import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';

void main() {
  group('Food', () {
    test('keeps the name it was given, trimmed', () {
      final food = Food(
        id: 1,
        name: '  Avena  ',
        per100g: const Macros(calories: 380),
      );

      expect(food.name, 'Avena');
    });

    test('refuses a blank name', () {
      expect(
        () => Food(id: 1, name: '   ', per100g: Macros.empty),
        throwsArgumentError,
      );
    });

    test('is the app own until someone says otherwise', () {
      // The default matters: a food arriving from the form is the user's, and
      // a row that wrongly claims to be shipped would survive a reseed for
      // the wrong reason.
      expect(
        Food(id: 0, name: 'Licuado', per100g: Macros.empty).isBuiltIn,
        isFalse,
      );
    });

    test('keeps where it came from through a correction', () {
      // Correcting a shipped food does not turn it into the user's invention.
      final food = Food(
        id: 1,
        name: 'Milanesa de carne',
        per100g: const Macros(calories: 280),
        isBuiltIn: true,
      );

      expect(
        food.copyWith(per100g: const Macros(calories: 290)).isBuiltIn,
        isTrue,
      );
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

    test('holds the figures for whatever was on the plate', () {
      // An entry's macros are absolute and stay that way. There is no route
      // back from them to a per-100 g figure — the weight they were measured
      // against is not recorded — which is exactly why the food database is
      // seeded and added to on purpose rather than filled from what is eaten.
      final entry = FoodEntry(
        id: 3,
        date: DateTime(2026, 3, 11),
        name: 'Avena',
        portion: '80 g',
        macros: const Macros(calories: 300),
        meal: Meal.breakfast,
      );

      expect(entry.portion, '80 g');
      expect(entry.macros, const Macros(calories: 300));
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
