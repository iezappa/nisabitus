import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/exercise/domain/exercise.dart';

void main() {
  final today = DateTime(2026, 3, 11);

  Exercise exercise(int id, String name) => Exercise(id: id, name: name);

  ExerciseSet set({
    int id = 1,
    int exerciseId = 1,
    int reps = 10,
    double? weight = 50,
    int position = 0,
  }) => ExerciseSet(
    id: id,
    exerciseId: exerciseId,
    date: today,
    reps: reps,
    weight: weight,
    position: position,
  );

  group('Exercise', () {
    test('rejects a blank name', () {
      expect(() => Exercise(id: 1, name: '   '), throwsArgumentError);
    });
  });

  group('ExerciseSet', () {
    test('rejects reps outside a sane range', () {
      expect(() => set(reps: 0), throwsArgumentError);
      expect(() => set(reps: 1001), throwsArgumentError);
    });

    test('rejects an impossible weight', () {
      expect(() => set(weight: -1), throwsArgumentError);
      expect(() => set(weight: 1001), throwsArgumentError);
    });

    test('allows no weight at all, which is not zero', () {
      final bodyweight = set(weight: null);

      expect(bodyweight.weight, isNull);
      expect(bodyweight.volume, 0);
    });

    test('multiplies reps by weight for volume', () {
      expect(set(reps: 8, weight: 60).volume, 480);
    });

    test('normalizes the date to the day', () {
      final s = ExerciseSet(
        id: 1,
        exerciseId: 1,
        date: DateTime(2026, 3, 11, 19, 45),
        reps: 5,
      );

      expect(s.date, DateTime(2026, 3, 11));
    });
  });

  group('ExerciseBlock', () {
    test('adds up the reps and the volume', () {
      final block = ExerciseBlock(
        exercise: exercise(1, 'Sentadilla'),
        sets: [set(reps: 10, weight: 60), set(reps: 8, weight: 70)],
      );

      expect(block.totalReps, 18);
      expect(block.volume, 10 * 60 + 8 * 70);
    });

    test('reports the heaviest set', () {
      final block = ExerciseBlock(
        exercise: exercise(1, 'Sentadilla'),
        sets: [set(weight: 60), set(weight: 80), set(weight: 70)],
      );

      expect(block.topWeight, 80);
    });

    test('has no top weight when everything was bodyweight', () {
      final block = ExerciseBlock(
        exercise: exercise(1, 'Dominadas'),
        sets: [set(weight: null), set(weight: null)],
      );

      expect(block.topWeight, isNull);
      expect(block.totalReps, 20);
    });
  });

  group('WorkoutDay', () {
    final catalogue = {
      1: exercise(1, 'Sentadilla'),
      2: exercise(2, 'Press banca'),
    };

    test('is empty without sets', () {
      final day = WorkoutDay.from(const [], catalogue);

      expect(day.isEmpty, isTrue);
      expect(day.totalSets, 0);
    });

    test('groups the sets under their exercise', () {
      final day = WorkoutDay.from([
        set(id: 1, exerciseId: 1, position: 0),
        set(id: 2, exerciseId: 2, position: 1),
        set(id: 3, exerciseId: 1, position: 2),
      ], catalogue);

      expect(day.blocks, hasLength(2));
      expect(day.blocks.first.exercise.name, 'Sentadilla');
      expect(day.blocks.first.sets, hasLength(2));
    });

    test('keeps the order each exercise first appeared', () {
      final day = WorkoutDay.from([
        set(id: 1, exerciseId: 2, position: 0),
        set(id: 2, exerciseId: 1, position: 1),
      ], catalogue);

      expect(day.blocks.map((b) => b.exercise.id), [2, 1]);
    });

    test('orders the sets within a block by position', () {
      final day = WorkoutDay.from([
        set(id: 2, exerciseId: 1, reps: 8, position: 1),
        set(id: 1, exerciseId: 1, reps: 10, position: 0),
      ], catalogue);

      expect(day.blocks.single.sets.map((s) => s.reps), [10, 8]);
    });

    test('adds up the whole day', () {
      final day = WorkoutDay.from([
        set(id: 1, exerciseId: 1, reps: 10, weight: 60),
        set(id: 2, exerciseId: 2, reps: 5, weight: 40),
      ], catalogue);

      expect(day.totalSets, 2);
      expect(day.totalReps, 15);
      expect(day.totalVolume, 10 * 60 + 5 * 40);
    });

    test('drops sets whose exercise no longer exists', () {
      // Deleting an exercise cascades, but a stale read should not crash.
      final day = WorkoutDay.from([set(exerciseId: 99)], catalogue);

      expect(day.isEmpty, isTrue);
    });
  });
}
