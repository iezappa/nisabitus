import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';

void main() {
  FoodPart part(String name, double grams, Macros per100g) =>
      FoodPart(id: name, name: name, grams: grams, per100g: per100g);

  // Per 100 g, the way the database quotes everything.
  const chicken = Macros(calories: 165, protein: 31, carbs: 0, fat: 4);
  const rice = Macros(calories: 130, protein: 3, carbs: 28, fat: 0);

  group('a plate made of parts', () {
    test('is worth what its parts are worth', () {
      // 150 g of chicken and 200 g of rice: the lunch the whole feature is
      // for.
      final parts = [part('Pollo', 150, chicken), part('Arroz', 200, rice)];

      expect(parts.total.calories, 248 + 260);
      expect(parts.total.protein, 47 + 6);
      expect(parts.total.carbs, 0 + 56);
      expect(parts.total.fat, 6 + 0);
    });

    test('adds the rounded parts, not the rounded sum', () {
      // Each part is rounded as it is scaled, and those are the figures
      // printed under the total. Summing unrounded values would show a total
      // that does not match the lines above it, and the user checks it by eye.
      final parts = [
        part('A', 33, const Macros(calories: 100)),
        part('B', 33, const Macros(calories: 100)),
        part('C', 33, const Macros(calories: 100)),
      ];

      expect(parts.total.calories, 99);
    });

    test('weighs what went on the scale', () {
      final parts = [part('Pollo', 150, chicken), part('Arroz', 200, rice)];

      expect(parts.grams, 350);
    });
  });

  group('quoting the plate per 100 g', () {
    test('scales the whole thing back to its reference weight', () {
      // What makes a saved combination pickable like any other food.
      final parts = [part('Pollo', 150, chicken), part('Arroz', 200, rice)];

      final per100g = parts.per100g!;

      // 508 kcal over 350 g.
      expect(per100g.calories, 145);
      expect(per100g.protein, 15);
    });

    test('refuses a plate nothing was weighed on', () {
      // No weight is no reference, and dividing by zero grams would invent
      // one.
      final parts = [part('Pollo', 0, chicken)];

      expect(parts.per100g, isNull);
    });

    test('is null for no parts at all', () {
      expect(const <FoodPart>[].per100g, isNull);
    });
  });

  group('a part', () {
    test('contributes what it weighs', () {
      expect(part('Pollo', 50, chicken).macros.calories, 83);
    });

    test('refuses a blank name', () {
      expect(
        () => FoodPart(id: '1', name: '  ', grams: 100, per100g: chicken),
        throwsArgumentError,
      );
    });

    test('refuses a negative weight', () {
      expect(
        () => FoodPart(id: '1', name: 'Pollo', grams: -1, per100g: chicken),
        throwsArgumentError,
      );
    });
  });

  group('an entry', () {
    FoodEntry entry(List<FoodPart> parts) => FoodEntry(
      id: '1',
      date: DateTime(2026, 3, 11),
      name: 'Almuerzo',
      macros: parts.total,
      parts: parts,
    );

    test('says whether it was broken down', () {
      expect(entry(const []).isComposed, isFalse);
      expect(entry([part('Pollo', 150, chicken)]).isComposed, isTrue);
    });

    test('has no weight when nobody broke it down', () {
      // Null is not zero: a plate nobody broke down is a plate nobody broke
      // down.
      expect(entry(const []).totalGrams, isNull);
    });

    test('keeps its parts through a copy', () {
      final original = entry([part('Pollo', 150, chicken)]);

      expect(original.copyWith(id: '2').parts, hasLength(1));
    });
  });
}
