// drift exports an `isNull` expression builder that collides with the matcher.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> insertHabit() => db
      .into(db.habits)
      .insert(
        HabitsCompanion.insert(
          name: 'Meditar',
          frequency: 'DAILY',
          status: 'PENDING',
          createdAt: DateTime(2026, 3, 11),
          scheduledDate: DateTime(2026, 3, 11),
        ),
      );

  group('foreign keys', () {
    test('are enforced, rejecting a completion with no habit', () {
      expect(
        db
            .into(db.habitCompletions)
            .insert(
              HabitCompletionsCompanion.insert(
                habitId: 999,
                completionDate: DateTime(2026, 3, 11),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('cascade, so deleting a habit removes its completions', () async {
      final habitId = await insertHabit();
      await db
          .into(db.habitCompletions)
          .insert(
            HabitCompletionsCompanion.insert(
              habitId: habitId,
              completionDate: DateTime(2026, 3, 11),
            ),
          );

      await (db.delete(db.habits)..where((h) => h.id.equals(habitId))).go();

      expect(await db.select(db.habitCompletions).get(), isEmpty);
    });

    test('cascade down the project tree to tasks and their comments', () async {
      final rootId = await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(name: 'Nísabit'));
      final childId = await db
          .into(db.projects)
          .insert(
            ProjectsCompanion.insert(
              name: 'Módulo 1',
              parentId: Value(rootId),
            ),
          );
      final taskId = await db
          .into(db.todoTasks)
          .insert(
            TodoTasksCompanion.insert(
              title: 'Escribir el test',
              priority: 'MEDIUM',
              status: 'TODO',
              projectId: childId,
            ),
          );
      await db
          .into(db.taskComments)
          .insert(
            TaskCommentsCompanion.insert(
              taskId: taskId,
              content: 'Empezado',
              createdAt: DateTime(2026, 3, 11),
            ),
          );

      await (db.delete(db.projects)..where((p) => p.id.equals(rootId))).go();

      expect(await db.select(db.projects).get(), isEmpty);
      expect(await db.select(db.todoTasks).get(), isEmpty);
      expect(await db.select(db.taskComments).get(), isEmpty);
    });
  });

  group('one record per day', () {
    test('is enforced for sleep logs', () async {
      final date = DateTime(2026, 3, 11);
      await db
          .into(db.sleepLogs)
          .insert(SleepLogsCompanion.insert(hours: 7.5, date: date));

      expect(
        db
            .into(db.sleepLogs)
            .insert(SleepLogsCompanion.insert(hours: 8, date: date)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('is enforced for journal entries', () async {
      final date = DateTime(2026, 3, 11);
      await db
          .into(db.moodEntries)
          .insert(MoodEntriesCompanion.insert(content: 'Primera', date: date));

      expect(
        db
            .into(db.moodEntries)
            .insert(
              MoodEntriesCompanion.insert(content: 'Segunda', date: date),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('allows an upsert to replace the record of the same day', () async {
      final date = DateTime(2026, 3, 11);
      await db
          .into(db.sleepLogs)
          .insertOnConflictUpdate(
            SleepLogsCompanion.insert(hours: 7.5, date: date),
          );
      await db
          .into(db.sleepLogs)
          .insert(
            SleepLogsCompanion.insert(hours: 8, date: date),
            onConflict: DoUpdate(
              (_) => SleepLogsCompanion.custom(hours: const Constant(8)),
              target: [db.sleepLogs.date],
            ),
          );

      final logs = await db.select(db.sleepLogs).get();
      expect(logs, hasLength(1));
      expect(logs.single.hours, 8);
    });
  });

  group('defaults', () {
    test('leave a new habit ready to use', () async {
      await insertHabit();
      final habit = await db.select(db.habits).getSingle();

      expect(habit.targetCount, 1);
      expect(habit.repeatForever, isFalse);
      expect(habit.repeatDays, isEmpty);
      expect(habit.endDate, isNull);
    });

    test('start both streak counters at zero', () async {
      await db
          .into(db.streaks)
          .insert(
            StreaksCompanion.insert(
              name: 'Meditar',
              lastUpdated: DateTime(2026, 3, 11),
            ),
          );
      final streak = await db.select(db.streaks).getSingle();

      expect(streak.count, 0);
      expect(streak.maxStreak, 0);
    });
  });
}
