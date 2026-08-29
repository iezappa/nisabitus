import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/features/sleep/domain/sleep_log.dart';
import 'package:nisabit/features/sleep/domain/sleep_stats.dart';

void main() {
  SleepLog log(double hours, [int day = 1]) =>
      SleepLog(id: day, hours: hours, date: DateTime(2026, 3, day));

  group('SleepQuality.forHours', () {
    test('is optimal between seven and nine hours', () {
      expect(SleepQuality.forHours(7), SleepQuality.optimal);
      expect(SleepQuality.forHours(8), SleepQuality.optimal);
      expect(SleepQuality.forHours(9), SleepQuality.optimal);
    });

    test('is acceptable on the wider six to ten band', () {
      expect(SleepQuality.forHours(6), SleepQuality.acceptable);
      expect(SleepQuality.forHours(6.5), SleepQuality.acceptable);
      expect(SleepQuality.forHours(10), SleepQuality.acceptable);
    });

    test('is poor outside that band', () {
      expect(SleepQuality.forHours(5.5), SleepQuality.poor);
      expect(SleepQuality.forHours(10.5), SleepQuality.poor);
      expect(SleepQuality.forHours(0), SleepQuality.poor);
    });
  });

  group('SleepLog', () {
    test('exposes the quality derived from its hours', () {
      expect(log(8).quality, SleepQuality.optimal);
      expect(log(5).quality, SleepQuality.poor);
    });

    test('normalizes the date to the day', () {
      final entry = SleepLog(
        id: 1,
        hours: 7.5,
        date: DateTime(2026, 3, 11, 23, 40),
      );

      expect(entry.date, DateTime(2026, 3, 11));
    });

    test('rejects hours outside zero to twenty four', () {
      expect(() => log(-0.5), throwsArgumentError);
      expect(() => log(24.5), throwsArgumentError);
    });

    test('accepts the bounds', () {
      expect(log(0).hours, 0);
      expect(log(24).hours, 24);
    });
  });

  group('SleepStats', () {
    test('is empty without records', () {
      final stats = SleepStats.from(const []);

      expect(stats.isEmpty, isTrue);
      expect(stats.count, 0);
      expect(stats.latest, isNull);
    });

    test('averages the hours', () {
      final stats = SleepStats.from([log(7, 1), log(8, 2), log(9, 3)]);

      expect(stats.average, 8);
      expect(stats.count, 3);
    });

    test('reports the lowest and highest night', () {
      final stats = SleepStats.from([log(6.5, 1), log(9, 2), log(7, 3)]);

      expect(stats.minHours, 6.5);
      expect(stats.maxHours, 9);
    });

    test('reports the share of optimal nights as a whole percentage', () {
      // Three of four nights land in the seven to nine band.
      final stats = SleepStats.from([log(7, 1), log(8, 2), log(9, 3), log(5, 4)]);

      expect(stats.optimalPercent, 75);
    });

    test('takes the most recent night as the latest, whatever the order', () {
      final stats = SleepStats.from([log(6, 3), log(8, 10), log(7, 1)]);

      expect(stats.latest?.date, DateTime(2026, 3, 10));
      expect(stats.latest?.hours, 8);
    });

    test('reports perfect consistency when every night is the same', () {
      final stats = SleepStats.from([log(8, 1), log(8, 2), log(8, 3)]);

      expect(stats.consistency, 0);
    });

    test('grows the consistency figure as nights scatter', () {
      final steady = SleepStats.from([log(7.5, 1), log(8, 2), log(8.5, 3)]);
      final erratic = SleepStats.from([log(4, 1), log(8, 2), log(12, 3)]);

      expect(steady.consistency, lessThan(erratic.consistency));
    });

    test('averages a single night to itself', () {
      final stats = SleepStats.from([log(7.5)]);

      expect(stats.average, 7.5);
      expect(stats.consistency, 0);
      expect(stats.optimalPercent, 100);
    });
  });
}
