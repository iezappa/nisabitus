import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/exercise/data/drift_exercise_repository.dart';
import 'package:nisabitus/features/exercise/domain/exercise.dart';
import 'package:nisabitus/features/exercise/domain/exercise_repository.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExerciseRepository(db);
  });
  tearDown(() => db.close());

  Future<Exercise> create(String name, {String? group}) =>
      repository.createExercise(ExerciseDraft(name: name, muscleGroup: group));

  group('the catalogue', () {
    test('starts empty', () async {
      expect(await repository.exercises(), isEmpty);
    });

    test('is alphabetical, not insertion order', () async {
      await create('Sentadilla');
      await create('Dominadas');
      await create('Press banca');

      expect((await repository.exercises()).map((e) => e.name), [
        'Dominadas',
        'Press banca',
        'Sentadilla',
      ]);
    });

    test('rejects a blank name', () {
      expect(() => create('  '), throwsArgumentError);
    });

    test('keeps the description and the muscle group', () async {
      await repository.createExercise(
        const ExerciseDraft(
          name: 'Peso muerto',
          description: 'Espalda recta, cadera atrás.',
          muscleGroup: 'Posterior',
        ),
      );

      final stored = (await repository.exercises()).single;
      expect(stored.description, 'Espalda recta, cadera atrás.');
      expect(stored.muscleGroup, 'Posterior');
    });

    test('can be edited', () async {
      final exercise = await create('Sentadilla');

      await repository.updateExercise(
        exercise.id,
        const ExerciseDraft(name: 'Sentadilla frontal', muscleGroup: 'Piernas'),
      );

      expect((await repository.exercises()).single.name, 'Sentadilla frontal');
    });
  });

  group('sets', () {
    test('are logged against the day they were done', () async {
      final exercise = await create('Sentadilla');
      await repository.logSet(
        monday,
        exerciseId: exercise.id,
        reps: 10,
        weight: 60,
      );

      expect((await repository.workoutFor(monday)).totalSets, 1);
      expect((await repository.workoutFor(tuesday)).isEmpty, isTrue);
    });

    test('keep the order they were performed in', () async {
      final exercise = await create('Sentadilla');
      await repository.logSet(monday, exerciseId: exercise.id, reps: 10);
      await repository.logSet(monday, exerciseId: exercise.id, reps: 8);
      await repository.logSet(monday, exerciseId: exercise.id, reps: 6);

      final block = (await repository.workoutFor(monday)).blocks.single;
      expect(block.sets.map((s) => s.reps), [10, 8, 6]);
    });

    test('number themselves per day, not across days', () async {
      final exercise = await create('Sentadilla');
      await repository.logSet(monday, exerciseId: exercise.id, reps: 10);
      await repository.logSet(monday, exerciseId: exercise.id, reps: 8);

      final first = await repository.logSet(
        tuesday,
        exerciseId: exercise.id,
        reps: 12,
      );

      // Tuesday starts over, so a new day's first set is not buried after
      // everything logged on Monday.
      expect(first.position, 0);
    });

    test('accept bodyweight, which is not zero', () async {
      final exercise = await create('Dominadas');
      await repository.logSet(monday, exerciseId: exercise.id, reps: 12);

      final set = (await repository.workoutFor(monday))
          .blocks
          .single
          .sets
          .single;
      expect(set.weight, isNull);
      expect(set.volume, 0);
    });

    test('reject impossible reps', () async {
      final exercise = await create('Sentadilla');

      expect(
        () => repository.logSet(monday, exerciseId: exercise.id, reps: 0),
        throwsArgumentError,
      );
    });

    test('can be edited', () async {
      final exercise = await create('Sentadilla');
      final set = await repository.logSet(
        monday,
        exerciseId: exercise.id,
        reps: 10,
        weight: 60,
      );

      await repository.updateSet(set.id, reps: 8, weight: 70);

      final stored = (await repository.workoutFor(monday))
          .blocks
          .single
          .sets
          .single;
      expect(stored.reps, 8);
      expect(stored.weight, 70);
    });

    test('can be removed one at a time', () async {
      final exercise = await create('Sentadilla');
      final set = await repository.logSet(
        monday,
        exerciseId: exercise.id,
        reps: 10,
      );
      await repository.logSet(monday, exerciseId: exercise.id, reps: 8);

      await repository.deleteSet(set.id);

      expect((await repository.workoutFor(monday)).totalSets, 1);
    });

    test('go away with the exercise they belong to', () async {
      final exercise = await create('Sentadilla');
      await repository.logSet(monday, exerciseId: exercise.id, reps: 10);

      await repository.deleteExercise(exercise.id);

      expect((await repository.workoutFor(monday)).isEmpty, isTrue);
    });
  });

  group('the day', () {
    test('groups the sets under each exercise', () async {
      final squat = await create('Sentadilla');
      final bench = await create('Press banca');
      await repository.logSet(
        monday,
        exerciseId: squat.id,
        reps: 10,
        weight: 60,
      );
      await repository.logSet(
        monday,
        exerciseId: bench.id,
        reps: 8,
        weight: 40,
      );
      await repository.logSet(
        monday,
        exerciseId: squat.id,
        reps: 8,
        weight: 70,
      );

      final day = await repository.workoutFor(monday);

      expect(day.blocks, hasLength(2));
      expect(day.blocks.first.exercise.name, 'Sentadilla');
      expect(day.blocks.first.sets, hasLength(2));
    });

    test('adds up sets, reps and volume', () async {
      final exercise = await create('Sentadilla');
      await repository.logSet(
        monday,
        exerciseId: exercise.id,
        reps: 10,
        weight: 60,
      );
      await repository.logSet(
        monday,
        exerciseId: exercise.id,
        reps: 8,
        weight: 70,
      );

      final day = await repository.workoutFor(monday);

      expect(day.totalSets, 2);
      expect(day.totalReps, 18);
      expect(day.totalVolume, 10 * 60 + 8 * 70);
    });
  });

  group('statsFor', () {
    test('reads the window as empty before anything is logged', () async {
      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.isEmpty, isTrue);
    });

    test('counts the sets of the window and leaves the rest out', () async {
      final squat = await create('Sentadilla');
      await repository.logSet(
        monday,
        exerciseId: squat.id,
        reps: 10,
        weight: 50,
      );
      await repository.logSet(
        tuesday,
        exerciseId: squat.id,
        reps: 8,
        weight: 60,
      );
      await repository.logSet(
        DateTime(2026, 3, 20),
        exerciseId: squat.id,
        reps: 5,
        weight: 100,
      );

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.sets, 2);
      expect(stats.reps, 18);
      expect(stats.volume, 980);
      expect(stats.daysTrained, 2);
    });

    test('forgets the sets of an exercise that was deleted', () async {
      final squat = await create('Sentadilla');
      await repository.logSet(
        monday,
        exerciseId: squat.id,
        reps: 10,
        weight: 50,
      );

      await repository.deleteExercise(squat.id);

      expect(
        (await repository.statsFor(DateRange(monday, tuesday))).isEmpty,
        isTrue,
      );
    });
  });
}
