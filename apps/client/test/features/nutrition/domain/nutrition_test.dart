import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';

void main() {
  final goal = NutritionGoal(calories: 2000, protein: 100, carbs: 200, fat: 60);

  FoodEntry entry({
    int id = 1,
    String name = 'Avena',
    int kcal = 300,
    int p = 10,
    int c = 50,
    int f = 5,
  }) => FoodEntry(
    id: id,
    date: DateTime(2026, 3, 11),
    name: name,
    macros: Macros(calories: kcal, protein: p, carbs: c, fat: f),
  );

  group('Macros', () {
    test('add up field by field', () {
      const a = Macros(calories: 100, protein: 10, carbs: 20, fat: 5);
      const b = Macros(calories: 250, protein: 30, carbs: 5, fat: 12);

      expect(
        a + b,
        const Macros(calories: 350, protein: 40, carbs: 25, fat: 17),
      );
    });

    test('start empty', () {
      expect(Macros.empty.isEmpty, isTrue);
      expect(const Macros(calories: 1).isEmpty, isFalse);
    });

    test('compare by value', () {
      expect(const Macros(calories: 10), const Macros(calories: 10));
      expect(const Macros(calories: 10), isNot(const Macros(calories: 11)));
    });
  });

  group('NutritionGoal', () {
    test('rejects a negative or absurd target', () {
      expect(
        () => NutritionGoal(calories: -1, protein: 0, carbs: 0, fat: 0),
        throwsArgumentError,
      );
      expect(
        () => NutritionGoal(calories: 20001, protein: 0, carbs: 0, fat: 0),
        throwsArgumentError,
      );
    });

    test('knows when nothing was set', () {
      expect(
        NutritionGoal(calories: 0, protein: 0, carbs: 0, fat: 0).isUnset,
        isTrue,
      );
      expect(NutritionGoal.fallback.isUnset, isFalse);
    });
  });

  group('FoodEntry', () {
    test('normalizes the date to the day', () {
      final e = FoodEntry(
        id: 1,
        date: DateTime(2026, 3, 11, 21, 30),
        name: 'Cena',
        macros: Macros.empty,
      );

      expect(e.date, DateTime(2026, 3, 11));
    });

    test('rejects a blank name', () {
      expect(
        () => FoodEntry(
          id: 1,
          date: DateTime(2026, 3, 11),
          name: '  ',
          macros: Macros.empty,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DailyNutrition', () {
    test('is empty before anything is logged', () {
      final day = DailyNutrition.from(const [], goal);

      expect(day.isEmpty, isTrue);
      expect(day.total, Macros.empty);
    });

    test('adds up every entry of the day', () {
      final day = DailyNutrition.from([
        entry(id: 1, kcal: 300, p: 10, c: 50, f: 5),
        entry(id: 2, kcal: 700, p: 40, c: 60, f: 20),
      ], goal);

      expect(day.total.calories, 1000);
      expect(day.total.protein, 50);
    });

    test('reports how far the day has come towards each target', () {
      final day = DailyNutrition.from([
        entry(kcal: 1000, p: 50, c: 100, f: 30),
      ], goal);

      expect(day.caloriesRatio, 0.5);
      expect(day.proteinRatio, 0.5);
      expect(day.carbsRatio, 0.5);
      expect(day.fatRatio, 0.5);
    });

    test('caps the ratio at one so the bar never overflows', () {
      final day = DailyNutrition.from([entry(kcal: 5000)], goal);

      expect(day.caloriesRatio, 1.0);
    });

    test('reports what is left of the budget, going negative once spent', () {
      expect(
        DailyNutrition.from([entry(kcal: 1200)], goal).caloriesRemaining,
        800,
      );
      expect(
        DailyNutrition.from([entry(kcal: 2500)], goal).caloriesRemaining,
        -500,
      );
    });

    test(
      'reads a target of zero as no progress rather than dividing by it',
      () {
        final none = NutritionGoal(calories: 0, protein: 0, carbs: 0, fat: 0);

        expect(DailyNutrition.from([entry()], none).caloriesRatio, 0);
      },
    );
  });
}
