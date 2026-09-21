// The v14 step cannot translate a reference to a parent that no longer
// exists: there is no new id to point at. Those rows are deleted rather than
// failing the whole upgrade on them — and deleting one orphans its own
// children in turn, which is why the deletion runs in a loop until a pass
// removes nothing.
//
// `migration_v14_test.dart` seeds only valid references, so its
// `PRAGMA foreign_key_check` assertion would pass with the loop deleted
// entirely. These tests seed real orphans, including a chain four levels
// deep, and name exactly which rows survive.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';

import 'generated/schema.dart';

/// Unix seconds, the way drift stored a DateTime at v13.
int _s(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  final created = DateTime(2026, 1, 2, 3, 4, 5);
  final day = DateTime(2026, 3, 11);

  /// A v13 store seeded with orphans alongside rows that are perfectly fine.
  ///
  /// Foreign keys are off on this raw connection — which is exactly how these
  /// rows got there on a real device, since the app only turned them on in
  /// `beforeOpen` from a later version.
  Future<AppDatabase> migratedFromOrphanedV13() async {
    final schema = await verifier.schemaAt(13);
    final before = _RawDatabase(schema.newConnection());
    Future<void> run(String sql) => before.customStatement(sql);

    await run(
      "INSERT INTO habits (id, name, frequency, target_count, repeat_forever, "
      "repeat_days, status, created_at, scheduled_date) VALUES "
      "(5, 'Leer', 'DAILY', 1, 0, '', 'ACTIVE', ${_s(created)}, ${_s(day)})",
    );
    // Only the first belongs to a habit that exists.
    await run(
      "INSERT INTO habit_completions (id, habit_id, completion_date) VALUES "
      "(1, 5, ${_s(day)}), (2, 404, ${_s(day)})",
    );

    await run(
      "INSERT INTO streaks (id, name, count, max_streak, last_updated) "
      "VALUES (1, 'Sin azúcar', 3, 3, ${_s(created)})",
    );
    await run(
      "INSERT INTO streak_history_entries (id, streak_id, count, reached_at) "
      "VALUES (1, 1, 3, ${_s(day)}), (2, 404, 9, ${_s(day)})",
    );

    // `Raíz` is sound. `Huérfano` points at a project that is gone, and
    // `Nieto` points at `Huérfano`: the second only becomes an orphan once
    // the first is deleted, which is what the loop is for.
    await run(
      "INSERT INTO projects (id, name, parent_id) VALUES "
      "(1, 'Raíz', NULL), (10, 'Huérfano', 404), (11, 'Nieto', 10)",
    );
    // Third level: the task is only orphaned once `Nieto` goes.
    await run(
      "INSERT INTO todo_tasks (id, title, priority, status, project_id) "
      "VALUES (1, 'Viva', 'LOW', 'TODO', 1), "
      "(2, 'Condenada', 'HIGH', 'TODO', 11)",
    );
    // Fourth level: the comment is only orphaned once the task goes.
    await run(
      "INSERT INTO task_comments (id, task_id, content, created_at) VALUES "
      "(1, 1, 'Sigue', ${_s(created)}), (2, 2, 'Se va', ${_s(created)})",
    );

    await run("INSERT INTO exercises (id, name) VALUES (1, 'Sentadilla')");
    await run(
      "INSERT INTO scheduled_exercises (id, exercise_id, scheduled_date, "
      "sets, reps, completed, repeat_days, repeat_forever) VALUES "
      "(1, 1, ${_s(day)}, 4, 8, 0, '', 0), "
      "(2, 404, ${_s(day)}, 4, 8, 0, '', 0)",
    );

    await run(
      "INSERT INTO medications (id, name, kind, active) VALUES "
      "(1, 'Vitamina D', 'SUPPLEMENT', 1)",
    );
    await run(
      "INSERT INTO medication_intakes (id, medication_id, date) VALUES "
      "(1, 1, ${_s(day)}), (2, 404, ${_s(day)})",
    );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
    return db;
  }

  test('removes the direct orphans and keeps every sound row', () async {
    final db = await migratedFromOrphanedV13();

    final habit = await db.select(db.habits).getSingle();
    final completion = await db.select(db.habitCompletions).getSingle();
    expect(completion.habitId, habit.id);

    final streak = await db.select(db.streaks).getSingle();
    final history = await db.select(db.streakHistoryEntries).getSingle();
    expect(history.streakId, streak.id);
    expect(history.count, 3);

    final exercise = await db.select(db.exercises).getSingle();
    expect(
      (await db.select(db.scheduledExercises).getSingle()).exerciseId,
      exercise.id,
    );

    final medication = await db.select(db.medications).getSingle();
    expect(
      (await db.select(db.medicationIntakes).getSingle()).medicationId,
      medication.id,
    );
  });

  test('keeps deleting until the chain of orphans is gone', () async {
    // One pass would remove `Huérfano` and stop, leaving `Nieto` pointing at
    // a project that no longer exists and its task and comment behind it.
    final db = await migratedFromOrphanedV13();

    expect((await db.select(db.projects).get()).map((p) => p.name), [
      'Raíz',
    ], reason: 'Huérfano and Nieto both had to go');
    expect((await db.select(db.todoTasks).get()).map((t) => t.title), ['Viva']);
    expect((await db.select(db.taskComments).get()).map((c) => c.content), [
      'Sigue',
    ]);
  });

  test('leaves a store with no broken reference at all', () async {
    final db = await migratedFromOrphanedV13();

    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

class _RawDatabase extends GeneratedDatabase {
  _RawDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 13;
}
