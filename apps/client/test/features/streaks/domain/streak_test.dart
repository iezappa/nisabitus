import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/streaks/domain/streak.dart';

void main() {
  final today = DateTime(2026, 3, 11);

  // Pinned to [today]: increment reads the gap since the last update, so a
  // streak born "now" would answer differently on every run.
  Streak newStreak() => Streak.create(id: 1, name: 'Meditar', createdAt: today);

  group('Streak.create', () {
    test('starts both counters at zero', () {
      final streak = newStreak();

      expect(streak.count, 0);
      expect(streak.maxStreak, 0);
    });

    test('rejects a blank name', () {
      expect(() => Streak.create(id: 1, name: '   '), throwsArgumentError);
    });

    test('trims the name', () {
      expect(Streak.create(id: 1, name: '  Meditar ').name, 'Meditar');
    });
  });

  group('Streak.increment', () {
    test('raises the count by one', () {
      expect(newStreak().increment(today).count, 1);
    });

    test('raises the record when the count passes it', () {
      final streak = newStreak().increment(today).increment(today);

      expect(streak.count, 2);
      expect(streak.maxStreak, 2);
    });

    test('keeps the record when the count is still below it', () {
      final afterReset = newStreak()
          .increment(today)
          .increment(today)
          .increment(today)
          .reset(today);

      final revived = afterReset.increment(today);

      expect(revived.count, 1);
      expect(revived.maxStreak, 3);
    });

    test('stamps the update date', () {
      final streak = newStreak().increment(DateTime(2026, 3, 11, 22, 40));

      expect(streak.lastUpdated, DateTime(2026, 3, 11));
    });

    test('carries the run over to the day after', () {
      final streak = newStreak()
          .increment(today)
          .increment(DateTime(2026, 3, 12));

      expect(streak.count, 2);
      expect(streak.lastUpdated, DateTime(2026, 3, 12));
    });

    test('restarts the count when a whole day went unrecorded', () {
      // Nothing on the 12th: the run of the 11th is over, and the 13th
      // begins a new one rather than resuming the old.
      final streak = newStreak()
          .increment(today)
          .increment(today)
          .increment(DateTime(2026, 3, 13));

      expect(streak.count, 1);
      expect(streak.maxStreak, 2);
    });

    test('takes an earlier day as a correction, not as a new day', () {
      // The user ticks a day they forgot at the time. It adds to the run,
      // but dragging the stamp backwards would turn the days already
      // recorded after it into a gap.
      final streak = newStreak()
          .increment(DateTime(2026, 3, 12))
          .increment(today);

      expect(streak.count, 2);
      expect(streak.lastUpdated, DateTime(2026, 3, 12));
    });
  });

  group('Streak.reset', () {
    test('sends the count back to zero', () {
      expect(newStreak().increment(today).reset(today).count, 0);
    });

    test('preserves the record earned before resetting', () {
      final streak = newStreak().increment(today).increment(today).reset(today);

      expect(streak.maxStreak, 2);
    });

    test('rescues a record that is behind the count', () {
      // Guards against inconsistent imported data, where count outran maxStreak.
      final inconsistent = Streak(
        id: 1,
        name: 'Meditar',
        count: 9,
        maxStreak: 4,
        lastUpdated: today,
      );

      expect(inconsistent.reset(today).maxStreak, 9);
    });

    test('stamps the update date', () {
      final streak = newStreak().reset(DateTime(2026, 3, 11, 22, 40));

      expect(streak.lastUpdated, DateTime(2026, 3, 11));
    });
  });

  group('Streak.rename', () {
    test('replaces the name', () {
      expect(newStreak().rename('Leer').name, 'Leer');
    });

    test('rejects a blank name', () {
      expect(() => newStreak().rename('  '), throwsArgumentError);
    });
  });
}
