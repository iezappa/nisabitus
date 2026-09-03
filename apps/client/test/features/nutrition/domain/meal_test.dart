import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';

void main() {
  group('parse', () {
    test('reads the stored value whatever its casing', () {
      expect(Meal.parse('BREAKFAST'), Meal.breakfast);
      expect(Meal.parse('  dinner '), Meal.dinner);
    });

    test('reads nothing as nothing', () {
      // An entry logged before the app asked which meal it belonged to has
      // no answer, and inventing one would put a lunch on the record that
      // nobody ate.
      expect(Meal.parse(null), isNull);
      expect(Meal.parse('   '), isNull);
    });

    test('rejects a value it does not know', () {
      expect(() => Meal.parse('BRUNCH'), throwsArgumentError);
    });
  });

  group('forHour', () {
    test('picks the meal the clock is closest to', () {
      expect(Meal.forHour(8), Meal.breakfast);
      expect(Meal.forHour(13), Meal.lunch);
      expect(Meal.forHour(17), Meal.snack);
      expect(Meal.forHour(21), Meal.dinner);
    });

    test('calls the small hours dinner rather than breakfast', () {
      // Something eaten at two in the morning belongs to the night that is
      // ending, not to the morning that has not started.
      expect(Meal.forHour(2), Meal.dinner);
    });

    test('covers every hour of the day', () {
      for (var hour = 0; hour < 24; hour++) {
        expect(Meal.forHour(hour), isNotNull, reason: 'hour $hour');
      }
    });
  });
}
