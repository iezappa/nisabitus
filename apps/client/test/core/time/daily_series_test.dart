import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/daily_series.dart';
import 'package:nisabitus/core/time/date_range.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 13));

  group('dailySeries', () {
    test('returns one point for every day of the window', () {
      final series = dailySeries(range, const {});

      expect(series.length, 5);
      expect(series.first.day, DateTime(2026, 3, 9));
      expect(series.last.day, DateTime(2026, 3, 13));
    });

    test('fills a day with no value with zero', () {
      final series = dailySeries(range, {DateTime(2026, 3, 11): 4});

      expect(series.map((point) => point.value), [0, 0, 4, 0, 0]);
    });

    test('normalizes the keys, so a stamped time still lands on its day', () {
      final series = dailySeries(range, {DateTime(2026, 3, 11, 22, 40): 4});

      expect(series[2].value, 4);
    });

    test('drops values outside the window', () {
      final series = dailySeries(range, {DateTime(2026, 3, 20): 9});

      expect(series.map((point) => point.value), [0, 0, 0, 0, 0]);
    });

    test('adds up values that normalize onto the same day', () {
      final series = dailySeries(range, {
        DateTime(2026, 3, 11, 8): 2,
        DateTime(2026, 3, 11, 20): 3,
      });

      expect(series[2].value, 5);
    });
  });
}
