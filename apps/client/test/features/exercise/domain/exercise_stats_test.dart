import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/exercise/domain/exercise.dart';
import 'package:nisabitus/features/exercise/domain/exercise_stats.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 13));

  ExerciseSet set(DateTime day, {int reps = 10, double? weight = 50}) =>
      ExerciseSet(
        id: 0,
        exerciseId: 1,
        date: day,
        reps: reps,
        weight: weight,
      );

  group('ExerciseStats', () {
    test('reads as empty when nothing was trained', () {
      final stats = ExerciseStats.from(range, const []);

      expect(stats.isEmpty, isTrue);
      expect(stats.daysTrained, 0);
      expect(stats.volume, 0);
    });

    test('counts sets, reps and volume across the window', () {
      final stats = ExerciseStats.from(range, [
        set(DateTime(2026, 3, 9), reps: 10, weight: 50),
        set(DateTime(2026, 3, 9), reps: 8, weight: 60),
        set(DateTime(2026, 3, 12), reps: 12, weight: 20),
      ]);

      expect(stats.sets, 3);
      expect(stats.reps, 30);
      expect(stats.volume, 500 + 480 + 240);
      expect(stats.daysTrained, 2);
    });

    test('counts bodyweight work as reps without volume', () {
      final stats = ExerciseStats.from(range, [
        set(DateTime(2026, 3, 9), reps: 15, weight: null),
      ]);

      expect(stats.reps, 15);
      expect(stats.volume, 0);
      // A day of push-ups is still a day trained.
      expect(stats.daysTrained, 1);
      expect(stats.isEmpty, isFalse);
    });

    test('plots volume for every day of the window, ascending', () {
      final stats = ExerciseStats.from(range, [
        set(DateTime(2026, 3, 10), reps: 10, weight: 40),
      ]);

      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[1].value, 400);
    });

    test('ignores sets outside the window', () {
      final stats = ExerciseStats.from(range, [
        set(DateTime(2026, 2, 1)),
        set(DateTime(2026, 3, 10)),
      ]);

      expect(stats.sets, 1);
    });
  });
}
