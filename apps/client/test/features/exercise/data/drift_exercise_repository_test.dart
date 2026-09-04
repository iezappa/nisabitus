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

  group('statsFor', () {
    test('reads the window as empty before anything is logged', () async {
      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.isEmpty, isTrue);
    });

    test('counts what was ticked off and leaves the rest out', () async {
      final squat = await create('Sentadilla');
      final monday3x10 = await repository.schedule(
        monday,
        ScheduledExerciseDraft(
          exerciseId: squat.id,
          sets: 3,
          reps: 10,
          weightKg: 50,
        ),
      );
      final tuesday4x8 = await repository.schedule(
        tuesday,
        ScheduledExerciseDraft(
          exerciseId: squat.id,
          sets: 4,
          reps: 8,
          weightKg: 60,
        ),
      );
      // Outside the window, and ticked off: it belongs to another week.
      final later = await repository.schedule(
        DateTime(2026, 3, 20),
        ScheduledExerciseDraft(
          exerciseId: squat.id,
          sets: 5,
          reps: 5,
          weightKg: 100,
        ),
      );
      for (final row in [monday3x10, tuesday4x8, later]) {
        await repository.complete(row.id, const ExerciseCompletion());
      }

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.sets, 7);
      expect(stats.reps, 62);
      expect(stats.volume, 3 * 10 * 50 + 4 * 8 * 60);
      expect(stats.daysTrained, 2);
    });

    test('leaves out a day that was written down and not done', () async {
      final squat = await create('Sentadilla');
      await repository.schedule(
        monday,
        ScheduledExerciseDraft(
          exerciseId: squat.id,
          sets: 3,
          reps: 10,
          weightKg: 50,
        ),
      );

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.isEmpty, isTrue);
      expect(stats.daysTrained, 0);
    });

    test('forgets the training of an exercise that was deleted', () async {
      final squat = await create('Sentadilla');
      final row = await repository.schedule(
        monday,
        ScheduledExerciseDraft(
          exerciseId: squat.id,
          sets: 3,
          reps: 10,
          weightKg: 50,
        ),
      );
      await repository.complete(row.id, const ExerciseCompletion());

      await repository.deleteExercise(squat.id);

      expect(
        (await repository.statsFor(DateRange(monday, tuesday))).isEmpty,
        isTrue,
      );
    });
  });
}
