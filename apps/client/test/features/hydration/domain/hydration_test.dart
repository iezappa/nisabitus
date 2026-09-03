import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/hydration/domain/hydration.dart';

void main() {
  final day = DateTime(2026, 3, 11);

  WaterEntry drink(int ml, {int id = 1}) =>
      WaterEntry(id: id, date: day, millilitres: ml);

  group('WaterEntry', () {
    test('keeps the day it was drunk on, without its time', () {
      final entry = WaterEntry(
        id: 1,
        date: DateTime(2026, 3, 11, 17, 42),
        millilitres: 250,
      );

      expect(entry.date, day);
    });

    test('refuses a drink of nothing', () {
      // Zero millilitres is not a small drink, it is a row that says nothing
      // and still counts as a day that was logged.
      expect(() => drink(0), throwsArgumentError);
    });

    test('refuses a drink nobody drank', () {
      expect(() => drink(5001), throwsArgumentError);
    });
  });

  group('HydrationGoal', () {
    test('starts on a target rather than on zero', () {
      expect(HydrationGoal.fallback.isUnset, isFalse);
    });

    test('refuses a target outside what a person drinks', () {
      expect(() => HydrationGoal(millilitres: -1), throwsArgumentError);
      expect(() => HydrationGoal(millilitres: 20001), throwsArgumentError);
    });
  });

  group('DailyHydration', () {
    test('is empty before anything is drunk', () {
      final day = DailyHydration.from(const [], HydrationGoal.fallback);

      expect(day.isEmpty, isTrue);
      expect(day.total, 0);
    });

    test('adds up every drink of the day', () {
      final today = DailyHydration.from([
        drink(250, id: 1),
        drink(500, id: 2),
      ], HydrationGoal.fallback);

      expect(today.total, 750);
    });

    test('reports how far the day has come', () {
      final today = DailyHydration.from([
        drink(1000),
      ], HydrationGoal(millilitres: 2000));

      expect(today.ratio, 0.5);
    });

    test('caps the ratio at one so the bar never overflows', () {
      final today = DailyHydration.from([
        drink(3000),
      ], HydrationGoal(millilitres: 2000));

      expect(today.ratio, 1);
    });

    test(
      'reads a target of zero as no progress rather than dividing by it',
      () {
        final today = DailyHydration.from([
          drink(500),
        ], HydrationGoal(millilitres: 0));

        expect(today.ratio, 0);
      },
    );

    test('reports what is left, going negative once the target is passed', () {
      final target = HydrationGoal(millilitres: 2000);

      expect(DailyHydration.from([drink(500)], target).remaining, 1500);
      expect(DailyHydration.from([drink(2500)], target).remaining, -500);
    });
  });
}
