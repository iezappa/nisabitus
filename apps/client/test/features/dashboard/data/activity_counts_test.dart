import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/dashboard/data/activity_counts.dart';

void main() {
  late AppDatabase db;
  late ActivityCounts counts;

  final monday = DateTime(2026, 9, 7);
  final tuesday = DateTime(2026, 9, 8);
  final week = DateRange(monday, monday.add(const Duration(days: 6)));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    counts = ActivityCounts(db);
  });
  tearDown(() => db.close());

  Future<String> aHabit() async {
    final row = await db
        .into(db.habits)
        .insertReturning(
          HabitsCompanion.insert(
            name: 'Caminar',
            frequency: 'daily',
            status: 'active',
            createdAt: monday,
            scheduledDate: monday,
          ),
        );
    return row.id;
  }

  Future<void> completed(String habitId, DateTime day) => db
      .into(db.habitCompletions)
      .insert(
        HabitCompletionsCompanion.insert(habitId: habitId, completionDate: day),
      );

  Future<void> drank(DateTime day) => db
      .into(db.waterEntries)
      .insert(WaterEntriesCompanion.insert(date: day, millilitres: 500));

  group('what a day holds', () {
    test('is nothing at all when nothing was written down', () async {
      expect(await counts.perDay(week), isEmpty);
    });

    test('leaves a silent day out rather than calling it zero', () async {
      await drank(monday);

      final perDay = await counts.perDay(week);

      expect(perDay[monday], 1);
      expect(perDay.containsKey(tuesday), isFalse);
    });

    test('adds up across modules', () async {
      final habit = await aHabit();
      await completed(habit, monday);
      await drank(monday);
      await drank(monday);

      expect((await counts.perDay(week))[monday], 3);
    });

    test('files an entry on its own day, not the one after', () async {
      // Recorded late at night: the stamp is nearly tomorrow in UTC, and a
      // day here is the user's own midnight.
      await db
          .into(db.pomodoroSessions)
          .insert(
            PomodoroSessionsCompanion.insert(
              name: 'Estudiar',
              status: 'completed',
              startedAt: DateTime(2026, 9, 7, 23, 40),
            ),
          );

      expect((await counts.perDay(week))[monday], 1);
      expect((await counts.perDay(week))[tuesday], isNull);
    });

    test('holds the last day of the window whole', () async {
      final evening = DateTime(2026, 9, 13, 21, 15);
      await db
          .into(db.pomodoroSessions)
          .insert(
            PomodoroSessionsCompanion.insert(
              name: 'Estudiar',
              status: 'completed',
              startedAt: evening,
            ),
          );

      expect((await counts.perDay(week))[DateTime(2026, 9, 13)], 1);
    });

    test('ignores what happened outside the window', () async {
      await drank(monday.subtract(const Duration(days: 1)));
      await drank(monday.add(const Duration(days: 30)));

      expect(await counts.perDay(week), isEmpty);
    });
  });

  group('what counts as activity', () {
    test('is doing a thing, not having it scheduled', () async {
      final exercise = await db
          .into(db.exercises)
          .insertReturning(ExercisesCompanion.insert(name: 'Sentadillas'));
      await db
          .into(db.scheduledExercises)
          .insert(
            ScheduledExercisesCompanion.insert(
              exerciseId: exercise.id,
              scheduledDate: monday,
              sets: 3,
              reps: 10,
            ),
          );

      expect(await counts.perDay(week), isEmpty);

      await db
          .update(db.scheduledExercises)
          .write(const ScheduledExercisesCompanion(completed: Value(true)));

      expect((await counts.perDay(week))[monday], 1);
    });

    test('is a task being finished, on the day it was finished', () async {
      final project = await db
          .into(db.projects)
          .insertReturning(ProjectsCompanion.insert(name: 'Casa'));
      await db.seedBoardColumnsFor(project.id);
      final column = (await db.select(db.boardColumns).get()).first;

      await db
          .into(db.todoTasks)
          .insert(
            TodoTasksCompanion.insert(
              title: 'Ordenar',
              priority: 'medium',
              columnId: column.id,
              projectId: project.id,
            ),
          );

      // Open: nothing was done.
      expect(await counts.perDay(week), isEmpty);

      await db
          .update(db.todoTasks)
          .write(TodoTasksCompanion(completedAt: Value(tuesday)));

      expect((await counts.perDay(week))[tuesday], 1);
    });
  });

  test('every table is either counted or named as ignored', () {
    // The grid is read as "everything I did", so a module added later must
    // be decided about rather than silently left out of it.
    final known = {...ActivityCounts.countedTables, ...ActivityCounts.ignored};
    final actual = {for (final table in db.allTables) table.actualTableName};

    expect(
      actual.difference(known),
      isEmpty,
      reason: 'new tables: add them to _sources or to ignored',
    );
    expect(
      known.difference(actual),
      isEmpty,
      reason: 'these tables no longer exist',
    );
  });
}
