import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/weekday.dart';
import 'package:nisabitus/features/exercise/data/drift_exercise_repository.dart';
import 'package:nisabitus/features/exercise/domain/exercise_repository.dart';
import 'package:nisabitus/features/exercise/domain/scheduled_exercise.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository repository;

  // A Monday, so the weekday arithmetic reads.
  final monday = DateTime(2026, 3, 9);
  final wednesday = DateTime(2026, 3, 11);
  final nextMonday = DateTime(2026, 3, 16);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExerciseRepository(db);
  });
  tearDown(() => db.close());

  Future<int> anExercise([String name = 'Sentadilla']) async =>
      (await repository.createExercise(ExerciseDraft(name: name))).id;

  ScheduledExerciseDraft draft(
    int exerciseId, {
    int sets = 4,
    int reps = 8,
    double? weight = 80,
    int? rpe,
    String? comments,
  }) => ScheduledExerciseDraft(
    exerciseId: exerciseId,
    sets: sets,
    reps: reps,
    weightKg: weight,
    rpe: rpe,
    comments: comments,
  );

  ExerciseRecurrence twiceAWeek({int weeks = 2}) => ExerciseRecurrence(
    days: const {Weekday.monday, Weekday.wednesday},
    type: RecurrenceType.weeks,
    weeks: weeks,
  );

  group('one day', () {
    test('writes an exercise down and reads it back on its day', () async {
      final exerciseId = await anExercise();

      await repository.schedule(
        monday,
        draft(exerciseId, comments: 'Bajar hasta paralelo'),
      );

      final stored = (await repository.scheduledFor(monday)).single;
      expect(stored.sets, 4);
      expect(stored.reps, 8);
      expect(stored.weightKg, 80);
      expect(stored.comments, 'Bajar hasta paralelo');
      expect(stored.completed, isFalse);
      expect(await repository.scheduledFor(wednesday), isEmpty);
    });

    test('belongs to no series when it does not repeat', () async {
      // And that matters: "stop repeating" must not be offered on something
      // that never repeated.
      final exerciseId = await anExercise();
      await repository.schedule(monday, draft(exerciseId));

      expect(
        (await repository.scheduledFor(monday)).single.isRecurring,
        isFalse,
      );
    });

    test('refuses a target the domain would not accept', () async {
      final exerciseId = await anExercise();

      expect(
        repository.schedule(monday, draft(exerciseId, sets: 0)),
        throwsArgumentError,
      );
      expect(await repository.scheduledFor(monday), isEmpty);
    });
  });

  group('a repetition', () {
    test('writes down a row for every day it lands on', () async {
      // Materialised, not computed: a day that has its own row can be
      // corrected and ticked without any of it reaching the days around it.
      final exerciseId = await anExercise();

      await repository.schedule(
        monday,
        draft(exerciseId),
        recurrence: twiceAWeek(),
      );

      expect(await repository.scheduledFor(monday), hasLength(1));
      expect(await repository.scheduledFor(wednesday), hasLength(1));
      expect(await repository.scheduledFor(nextMonday), hasLength(1));
    });

    test('ties its days together under one group', () async {
      final exerciseId = await anExercise();
      await repository.schedule(
        monday,
        draft(exerciseId),
        recurrence: twiceAWeek(),
      );

      final first = (await repository.scheduledFor(monday)).single;
      final second = (await repository.scheduledFor(wednesday)).single;

      expect(first.isRecurring, isTrue);
      expect(second.recurrenceGroupId, first.recurrenceGroupId);
    });

    test('carries the plan onto every copy', () async {
      final exerciseId = await anExercise();
      await repository.schedule(
        monday,
        draft(exerciseId, comments: 'Sin rebote'),
        recurrence: twiceAWeek(),
      );

      final copy = (await repository.scheduledFor(wednesday)).single;
      expect(copy.sets, 4);
      expect(copy.weightKg, 80);
      expect(copy.comments, 'Sin rebote');
      expect(copy.completed, isFalse);
    });

    test('leaves nothing behind when the recurrence is impossible', () async {
      // The days are worked out before anything is written, so a bad
      // repetition cannot leave the first day stranded on its own.
      final exerciseId = await anExercise();

      expect(
        repository.schedule(
          monday,
          draft(exerciseId),
          recurrence: ExerciseRecurrence(
            days: const {Weekday.monday},
            type: RecurrenceType.until,
            endDate: monday.subtract(const Duration(days: 7)),
          ),
        ),
        throwsArgumentError,
      );
      expect(await repository.scheduledFor(monday), isEmpty);
    });
  });

  group('correcting a day', () {
    test('changes that day and no other', () async {
      // The whole reason the days are written down separately.
      final exerciseId = await anExercise();
      await repository.schedule(
        monday,
        draft(exerciseId),
        recurrence: twiceAWeek(),
      );
      final first = (await repository.scheduledFor(monday)).single;

      await repository.updateScheduled(
        first.id,
        draft(exerciseId, sets: 6, weight: 100),
      );

      expect((await repository.scheduledFor(monday)).single.sets, 6);
      expect((await repository.scheduledFor(wednesday)).single.sets, 4);
    });

    test('refuses to correct a day that is not there', () async {
      final exerciseId = await anExercise();

      expect(
        repository.updateScheduled(404, draft(exerciseId)),
        throwsStateError,
      );
    });
  });

  group('ticking it off', () {
    test('records what actually happened', () async {
      final exerciseId = await anExercise();
      await repository.schedule(monday, draft(exerciseId));
      final row = (await repository.scheduledFor(monday)).single;

      await repository.complete(
        row.id,
        const ExerciseCompletion(
          weightKg: 85,
          rpe: 9,
          feedback: 'La última salió fea',
        ),
      );

      final done = (await repository.scheduledFor(monday)).single;
      expect(done.completed, isTrue);
      expect(done.weightKg, 85);
      expect(done.rpe, 9);
      expect(done.feedback, 'La última salió fea');
    });

    test('leaves the plan standing when nothing is said instead', () async {
      // Ticking something off without touching the weight means it went as
      // written, not that the weight is now unknown.
      final exerciseId = await anExercise();
      await repository.schedule(monday, draft(exerciseId, weight: 80));
      final row = (await repository.scheduledFor(monday)).single;

      await repository.complete(row.id, const ExerciseCompletion());

      final done = (await repository.scheduledFor(monday)).single;
      expect(done.completed, isTrue);
      expect(done.weightKg, 80);
    });

    test(
      'can be put back to pending without losing what was written',
      () async {
        // Un-ticking is saying it is not finished, not that it never happened.
        final exerciseId = await anExercise();
        await repository.schedule(monday, draft(exerciseId));
        final row = (await repository.scheduledFor(monday)).single;
        await repository.complete(
          row.id,
          const ExerciseCompletion(feedback: 'Pesó'),
        );

        await repository.reopen(row.id);

        final back = (await repository.scheduledFor(monday)).single;
        expect(back.completed, isFalse);
        expect(back.feedback, 'Pesó');
      },
    );
  });

  group('stopping a repetition', () {
    test('removes the later days that are still pending', () async {
      final exerciseId = await anExercise();
      await repository.schedule(
        monday,
        draft(exerciseId),
        recurrence: twiceAWeek(),
      );
      final first = (await repository.scheduledFor(monday)).single;

      await repository.stopRecurrence(first.id);

      expect(await repository.scheduledFor(monday), hasLength(1));
      expect(await repository.scheduledFor(wednesday), isEmpty);
      expect(await repository.scheduledFor(nextMonday), isEmpty);
    });

    test('leaves a later day that was already trained', () async {
      // Stopping a repetition is not undoing the training under it.
      final exerciseId = await anExercise();
      await repository.schedule(
        monday,
        draft(exerciseId),
        recurrence: twiceAWeek(),
      );
      final later = (await repository.scheduledFor(wednesday)).single;
      await repository.complete(later.id, const ExerciseCompletion());
      final first = (await repository.scheduledFor(monday)).single;

      await repository.stopRecurrence(first.id);

      expect(await repository.scheduledFor(wednesday), hasLength(1));
      expect(await repository.scheduledFor(nextMonday), isEmpty);
    });

    test('stops the days from waiting for more to arrive', () async {
      final exerciseId = await anExercise();
      await repository.schedule(
        monday,
        draft(exerciseId),
        recurrence: ExerciseRecurrence(
          days: const {Weekday.monday},
          type: RecurrenceType.forever,
        ),
      );
      final first = (await repository.scheduledFor(monday)).single;

      await repository.stopRecurrence(first.id);

      expect(
        (await repository.scheduledFor(monday)).single.repeatForever,
        isFalse,
      );
    });

    test('refuses on something that never repeated', () async {
      final exerciseId = await anExercise();
      await repository.schedule(monday, draft(exerciseId));
      final row = (await repository.scheduledFor(monday)).single;

      expect(repository.stopRecurrence(row.id), throwsStateError);
    });
  });

  test('goes away with the movement it belongs to', () async {
    final exerciseId = await anExercise();
    await repository.schedule(
      monday,
      draft(exerciseId),
      recurrence: twiceAWeek(),
    );

    await repository.deleteExercise(exerciseId);

    expect(await repository.scheduledFor(monday), isEmpty);
    expect(await repository.scheduledFor(wednesday), isEmpty);
  });
}
