import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/weekday.dart';
import 'package:nisabitus/features/discipline/data/drift_discipline_repository.dart';
import 'package:nisabitus/features/discipline/domain/discipline_repository.dart';
import 'package:nisabitus/features/exercise/domain/scheduled_exercise.dart';

void main() {
  late AppDatabase db;
  late DisciplineRepository repository;

  // A Monday.
  final monday = DateTime(2026, 3, 9);
  final wednesday = DateTime(2026, 3, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDisciplineRepository(db);
  });
  tearDown(() => db.close());

  DisciplineDraft draft({
    String name = 'Natación',
    int minutes = 45,
    double? km = 2,
    String? notes,
  }) => DisciplineDraft(
    name: name,
    durationMinutes: minutes,
    distanceKm: km,
    notes: notes,
  );

  ExerciseRecurrence twiceAWeek() => ExerciseRecurrence(
    days: const {Weekday.monday, Weekday.wednesday},
    type: RecurrenceType.weeks,
    weeks: 2,
  );

  test('writes a session down with no catalogue behind it', () async {
    // What is practised is written as it is called. "Natación" does not need
    // a definition somewhere else before it can be logged.
    await repository.schedule(monday, draft(notes: 'Crol suave'));

    final stored = (await repository.forDay(monday)).single;
    expect(stored.name, 'Natación');
    expect(stored.durationMinutes, 45);
    expect(stored.distanceKm, 2);
    expect(stored.notes, 'Crol suave');
    expect(stored.completed, isFalse);
  });

  test('accepts a session with no distance at all', () async {
    // A yoga class has a duration and no kilometres. Zero would claim it was
    // measured.
    await repository.schedule(monday, draft(name: 'Yoga', km: null));

    expect((await repository.forDay(monday)).single.distanceKm, isNull);
  });

  test('refuses a session the domain would not accept', () async {
    expect(repository.schedule(monday, draft(minutes: 0)), throwsArgumentError);
    expect(repository.schedule(monday, draft(name: '  ')), throwsArgumentError);
    expect(await repository.forDay(monday), isEmpty);
  });

  test('writes down a row for every day a repetition lands on', () async {
    await repository.schedule(monday, draft(), recurrence: twiceAWeek());

    expect(await repository.forDay(monday), hasLength(1));
    expect(await repository.forDay(wednesday), hasLength(1));
    expect(
      (await repository.forDay(wednesday)).single.recurrenceGroupId,
      (await repository.forDay(monday)).single.recurrenceGroupId,
    );
  });

  test('corrects one day and no other', () async {
    await repository.schedule(monday, draft(), recurrence: twiceAWeek());
    final first = (await repository.forDay(monday)).single;

    await repository.update(first.id, draft(minutes: 60));

    expect((await repository.forDay(monday)).single.durationMinutes, 60);
    expect((await repository.forDay(wednesday)).single.durationMinutes, 45);
  });

  test('records what was actually done when ticked off', () async {
    await repository.schedule(monday, draft());
    final row = (await repository.forDay(monday)).single;

    await repository.complete(
      row.id,
      const DisciplineCompletion(
        durationMinutes: 50,
        distanceKm: 2.5,
        feedback: 'Fría el agua',
      ),
    );

    final done = (await repository.forDay(monday)).single;
    expect(done.completed, isTrue);
    expect(done.durationMinutes, 50);
    expect(done.distanceKm, 2.5);
    expect(done.feedback, 'Fría el agua');
  });

  test('leaves the plan standing when nothing is said instead', () async {
    await repository.schedule(monday, draft(minutes: 45));
    final row = (await repository.forDay(monday)).single;

    await repository.complete(row.id, const DisciplineCompletion());

    final done = (await repository.forDay(monday)).single;
    expect(done.completed, isTrue);
    expect(done.durationMinutes, 45);
  });

  test('puts one back to pending without losing what was written', () async {
    await repository.schedule(monday, draft());
    final row = (await repository.forDay(monday)).single;
    await repository.complete(
      row.id,
      const DisciplineCompletion(feedback: 'Costó'),
    );

    await repository.reopen(row.id);

    final back = (await repository.forDay(monday)).single;
    expect(back.completed, isFalse);
    expect(back.feedback, 'Costó');
  });

  test('stops a repetition from the day forward', () async {
    await repository.schedule(monday, draft(), recurrence: twiceAWeek());
    final first = (await repository.forDay(monday)).single;

    await repository.stopRecurrence(first.id);

    expect(await repository.forDay(monday), hasLength(1));
    expect(await repository.forDay(wednesday), isEmpty);
  });

  test('leaves a later day that was already practised', () async {
    // Stopping a repetition is not undoing what was practised under it.
    await repository.schedule(monday, draft(), recurrence: twiceAWeek());
    final later = (await repository.forDay(wednesday)).single;
    await repository.complete(later.id, const DisciplineCompletion());
    final first = (await repository.forDay(monday)).single;

    await repository.stopRecurrence(first.id);

    expect(await repository.forDay(wednesday), hasLength(1));
  });

  test(
    'refuses to stop a repetition on something that never repeated',
    () async {
      await repository.schedule(monday, draft());
      final row = (await repository.forDay(monday)).single;

      expect(repository.stopRecurrence(row.id), throwsStateError);
    },
  );
}
