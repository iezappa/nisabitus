import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/features/habits/domain/habit_repository.dart';
import 'package:nisabitus/core/time/weekday.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repository;

  final wednesday = DateTime(2026, 3, 11);
  final thursday = DateTime(2026, 3, 12);
  final nextMonday = DateTime(2026, 3, 16);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftHabitRepository(db);
  });
  tearDown(() => db.close());

  Future<Habit> create({
    String name = 'Meditar',
    HabitFrequency frequency = HabitFrequency.daily,
    int targetCount = 1,
    Set<Weekday> repeatDays = const {},
  }) => repository.create(
    HabitDraft(
      name: name,
      frequency: frequency,
      targetCount: targetCount,
      repeatDays: repeatDays,
    ),
    on: wednesday,
  );

  group('create', () {
    test('stores the habit as pending and not yet completed', () async {
      final habit = await create();

      expect(habit.name, 'Meditar');
      expect(habit.status, HabitStatus.pending);
      expect(habit.completed, isFalse);
    });

    test('round-trips the chosen weekdays', () async {
      await create(repeatDays: {Weekday.monday, Weekday.friday});

      final stored = (await repository.listForDay(wednesday)).single;
      expect(stored.repeatDays, {Weekday.monday, Weekday.friday});
    });

    test('rejects a blank name', () {
      expect(
        () => repository.create(
          const HabitDraft(name: '   ', frequency: HabitFrequency.daily),
          on: wednesday,
        ),
        throwsArgumentError,
      );
    });
  });

  group('listForDay', () {
    test('filters by frequency when asked', () async {
      await create(name: 'Diario');
      await create(name: 'Semanal', frequency: HabitFrequency.weekly);

      final daily = await repository.listForDay(
        wednesday,
        frequency: HabitFrequency.daily,
      );

      expect(daily.map((h) => h.name), ['Diario']);
    });

    test('returns every habit when no frequency is given', () async {
      await create(name: 'Diario');
      await create(name: 'Semanal', frequency: HabitFrequency.weekly);

      expect(await repository.listForDay(wednesday), hasLength(2));
    });
  });

  group('toggleCompletion on a daily habit', () {
    test('marks the habit done for that day', () async {
      final habit = await create();

      final toggled = await repository.toggleCompletion(habit.id, wednesday);

      expect(toggled.completed, isTrue);
      expect(toggled.status, HabitStatus.done);
    });

    test('leaves the next day untouched', () async {
      final habit = await create();
      await repository.toggleCompletion(habit.id, wednesday);

      final onThursday = (await repository.listForDay(thursday)).single;

      expect(onThursday.completed, isFalse);
      expect(onThursday.status, HabitStatus.pending);
    });

    test('undoes the completion when toggled again', () async {
      final habit = await create();
      await repository.toggleCompletion(habit.id, wednesday);

      final toggled = await repository.toggleCompletion(habit.id, wednesday);

      expect(toggled.completed, isFalse);
      expect(toggled.status, HabitStatus.pending);
    });
  });

  group('toggleCompletion on a weekly habit', () {
    test('marks the habit done for the rest of its week', () async {
      final habit = await create(frequency: HabitFrequency.weekly);
      await repository.toggleCompletion(habit.id, wednesday);

      final onThursday = (await repository.listForDay(thursday)).single;

      expect(onThursday.completed, isTrue);
    });

    test('does not spill into the following week', () async {
      final habit = await create(frequency: HabitFrequency.weekly);
      await repository.toggleCompletion(habit.id, wednesday);

      final onNextMonday = (await repository.listForDay(nextMonday)).single;

      expect(onNextMonday.completed, isFalse);
    });

    test('clears the whole period when toggled off from another day', () async {
      final habit = await create(frequency: HabitFrequency.weekly);
      await repository.toggleCompletion(habit.id, wednesday);

      final toggled = await repository.toggleCompletion(habit.id, thursday);

      expect(toggled.completed, isFalse);
      expect(
        await repository.totalCompletions(
          DateRange.lastDays(30, from: nextMonday),
        ),
        0,
      );
    });
  });

  group('changeStatus', () {
    test('to done records a completion when there is none', () async {
      final habit = await create();

      final changed = await repository.changeStatus(
        habit.id,
        HabitStatus.done,
        wednesday,
      );

      expect(changed.completed, isTrue);
      expect(changed.status, HabitStatus.done);
    });

    test('to done does not duplicate an existing completion', () async {
      final habit = await create();
      await repository.toggleCompletion(habit.id, wednesday);

      await repository.changeStatus(habit.id, HabitStatus.done, wednesday);

      expect(
        await repository.totalCompletions(DateRange(wednesday, wednesday)),
        1,
      );
    });

    test('to cancelled clears the completions of the period', () async {
      final habit = await create();
      await repository.toggleCompletion(habit.id, wednesday);

      final changed = await repository.changeStatus(
        habit.id,
        HabitStatus.cancelled,
        wednesday,
      );

      expect(changed.status, HabitStatus.cancelled);
      expect(changed.completed, isFalse);
    });

    test('to pending reverts a cancelled habit', () async {
      final habit = await create();
      await repository.changeStatus(habit.id, HabitStatus.cancelled, wednesday);

      final reverted = await repository.changeStatus(
        habit.id,
        HabitStatus.pending,
        wednesday,
      );

      expect(reverted.status, HabitStatus.pending);
    });

    test('keeps a cancelled habit out of the done state when listed', () async {
      final habit = await create();
      await repository.changeStatus(habit.id, HabitStatus.cancelled, wednesday);

      final listed = (await repository.listForDay(wednesday)).single;

      expect(listed.status, HabitStatus.cancelled);
    });
  });

  group('delete', () {
    test('removes the habit and its completions', () async {
      final habit = await create();
      await repository.toggleCompletion(habit.id, wednesday);

      await repository.delete(habit.id);

      expect(await repository.listForDay(wednesday), isEmpty);
      expect(
        await repository.totalCompletions(DateRange(wednesday, wednesday)),
        0,
      );
    });
  });

  group('completionsPerDay', () {
    test('counts how many habits were fulfilled on each day', () async {
      final a = await create(name: 'Meditar');
      final b = await create(name: 'Leer');
      await repository.toggleCompletion(a.id, wednesday);
      await repository.toggleCompletion(b.id, wednesday);
      await repository.toggleCompletion(a.id, thursday);

      final counts = await repository.completionsPerDay(
        DateRange(wednesday, thursday),
      );

      expect(counts, [(day: wednesday, count: 2), (day: thursday, count: 1)]);
    });

    test('leaves out days outside the range', () async {
      final habit = await create();
      await repository.toggleCompletion(habit.id, wednesday);
      await repository.toggleCompletion(habit.id, thursday);

      final counts = await repository.completionsPerDay(
        DateRange(wednesday, wednesday),
      );

      expect(counts, [(day: wednesday, count: 1)]);
    });

    test('returns an empty list when nothing was fulfilled', () async {
      await create();

      expect(
        await repository.completionsPerDay(DateRange(wednesday, thursday)),
        isEmpty,
      );
    });
  });
}
