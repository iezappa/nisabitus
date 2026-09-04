import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/nutrition/domain/food_portion.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';

void main() {
  // Oatmeal, near enough: the figures matter less than the arithmetic done
  // to them.
  const avena = Macros(calories: 380, protein: 13, carbs: 67, fat: 7);

  group('scaleMacros', () {
    test('quotes the food unchanged at exactly one hundred grams', () {
      expect(scaleMacros(avena, 100), avena);
    });

    test('halves the figures at half the weight', () {
      expect(
        scaleMacros(avena, 50),
        const Macros(calories: 190, protein: 7, carbs: 34, fat: 4),
      );
    });

    test('comes to nothing at no weight', () {
      // Zero grams of anything is zero, not the per-100 g figure. A form
      // that has not been given a weight yet must not claim a plateful.
      expect(scaleMacros(avena, 0), Macros.empty);
    });

    test('takes a weight that is not a whole number of grams', () {
      expect(scaleMacros(avena, 12.5).calories, 48);
    });

    test('rounds rather than truncates', () {
      // 380 * 12.5 / 100 is 47.5. Truncation would say 47, and it would say
      // less than the truth on almost every entry: the error only ever goes
      // one way, so a day of eating adds up to visibly less than it was.
      expect(scaleMacros(avena, 12.5).calories, 47.5.round());
      expect(scaleMacros(const Macros(calories: 1), 50).calories, 1);
    });

    test('scales a weight nobody would eat without overflowing', () {
      expect(scaleMacros(avena, 20000).calories, 76000);
    });

    test('refuses a negative weight', () {
      // Not clamped to zero: a negative weight is a bug upstream, and
      // silently reading it as an empty plate hides it.
      expect(() => scaleMacros(avena, -1), throwsArgumentError);
    });
  });

  group('parseGrams', () {
    test('reads a whole number', () {
      expect(parseGrams('150'), 150);
    });

    test('reads a decimal written with a comma', () {
      // Spanish writes 12,5. A field that only understands 12.5 refuses the
      // way the user was taught to write numbers.
      expect(parseGrams('12,5'), 12.5);
    });

    test('reads a decimal written with a point', () {
      expect(parseGrams('12.5'), 12.5);
    });

    test('ignores the space around it', () {
      expect(parseGrams('  150  '), 150);
    });

    test('has no answer for a blank field', () {
      // Blank is not zero. Nobody has said what this weighs yet.
      expect(parseGrams(''), isNull);
      expect(parseGrams('   '), isNull);
    });

    test('has no answer for something that is not a number', () {
      expect(parseGrams('un plato'), isNull);
    });

    test('has no answer for a negative weight', () {
      expect(parseGrams('-10'), isNull);
    });

    test('takes zero, which is a weight even if it is not a meal', () {
      expect(parseGrams('0'), 0);
    });

    test('refuses more than anyone eats in one sitting', () {
      expect(parseGrams('${maxPortionGrams + 1}'), isNull);
      expect(parseGrams('$maxPortionGrams'), maxPortionGrams);
    });
  });

  group('Food', () {
    test('works out what a weight of it comes to', () {
      final food = Food(id: 1, name: 'Avena', per100g: avena);

      expect(food.macrosFor(50).calories, 190);
    });
  });
}
