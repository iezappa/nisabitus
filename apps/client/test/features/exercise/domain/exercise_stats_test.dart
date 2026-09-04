import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/exercise/domain/exercise_stats.dart';
import 'package:nisabitus/features/exercise/domain/scheduled_exercise.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 13));

  ScheduledExercise row(
    DateTime day, {
    int sets = 3,
    int reps = 10,
    double? weightKg = 50,
    bool completed = true,
  }) => ScheduledExercise(
    id: 0,
    exerciseId: 1,
    scheduledDate: day,
    sets: sets,
    reps: reps,
    weightKg: weightKg,
    completed: completed,
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
        row(DateTime(2026, 3, 9), sets: 3, reps: 10, weightKg: 50),
        row(DateTime(2026, 3, 9), sets: 4, reps: 8, weightKg: 60),
        row(DateTime(2026, 3, 12), sets: 2, reps: 12, weightKg: 20),
      ]);

      expect(stats.sets, 3 + 4 + 2);
      expect(stats.reps, 30 + 32 + 24);
      expect(stats.volume, 1500 + 1920 + 480);
      expect(stats.daysTrained, 2);
    });

    test('leaves out what was planned and never done', () {
      final stats = ExerciseStats.from(range, [
        row(DateTime(2026, 3, 9), completed: true),
        row(DateTime(2026, 3, 10), completed: false),
      ]);

      expect(stats.sets, 3);
      expect(stats.reps, 30);
      expect(stats.volume, 1500);
      // The day nobody trained on is not a day trained.
      expect(stats.daysTrained, 1);
    });

    test('keeps a day whose only work was left undone, at zero', () {
      final stats = ExerciseStats.from(range, [
        row(DateTime(2026, 3, 9)),
        row(DateTime(2026, 3, 10), completed: false),
        row(DateTime(2026, 3, 11)),
      ]);

      // Dropping the day instead of zeroing it would slide the 11th into the
      // 10th's place and misdate every point after it.
      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay[1].day, DateTime(2026, 3, 10));
      expect(stats.perDay[1].value, 0);
      expect(stats.perDay[2].day, DateTime(2026, 3, 11));
      expect(stats.perDay[2].value, 1500);
    });

    test('counts the first and last day of the window', () {
      // The window is inclusive at both ends. An off-by-one here quietly
      // drops a day of training from every figure on the screen.
      final stats = ExerciseStats.from(range, [
        row(range.start),
        row(range.end),
      ]);

      expect(stats.daysTrained, 2);
      expect(stats.sets, 6);
      expect(stats.volume, 3000);
      expect(stats.perDay.first.value, 1500);
      expect(stats.perDay.last.value, 1500);
    });

    test('counts bodyweight work as reps without volume', () {
      final stats = ExerciseStats.from(range, [
        row(DateTime(2026, 3, 9), sets: 3, reps: 15, weightKg: null),
      ]);

      expect(stats.reps, 45);
      expect(stats.volume, 0);
      // A day of push-ups is still a day trained.
      expect(stats.daysTrained, 1);
      expect(stats.isEmpty, isFalse);
    });

    test('plots volume for every day of the window, ascending', () {
      final stats = ExerciseStats.from(range, [
        row(DateTime(2026, 3, 10), sets: 2, reps: 10, weightKg: 40),
      ]);

      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[1].value, 800);
    });

    test('ignores rows outside the window', () {
      final stats = ExerciseStats.from(range, [
        row(DateTime(2026, 2, 1)),
        row(DateTime(2026, 3, 10)),
      ]);

      expect(stats.sets, 3);
    });
  });
}
