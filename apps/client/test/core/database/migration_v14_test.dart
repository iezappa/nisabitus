// v14 replaces every autoincrement id with a UUID and stamps every row with
// `updatedAt` (STACK-APPS-DINAMICAS.md 1.1). Every reference between tables
// is rewritten in the same step, so these tests seed a v13 store whose ids
// deliberately collide across tables and run out of order, then check that
// each child still points at the parent it pointed at before.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/uuid.dart';

import 'generated/schema.dart';

/// Unix seconds, the way drift stored a DateTime at v13.
int _s(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  final created = DateTime(2026, 1, 2, 3, 4, 5);
  final day = DateTime(2026, 3, 11);

  /// A v13 store with a row in every table and every kind of reference.
  Future<AppDatabase> migratedFromSeededV13() async {
    final schema = await verifier.schemaAt(13);
    final raw = schema.newConnection();
    final before = _RawDatabase(raw);
    Future<void> run(String sql) => before.customStatement(sql);

    await run(
      "INSERT INTO habits (id, name, frequency, target_count, repeat_forever, "
      "repeat_days, status, created_at, scheduled_date) VALUES "
      "(5, 'Leer', 'DAILY', 1, 0, '', 'ACTIVE', ${_s(created)}, ${_s(day)}), "
      "(7, 'Meditar', 'DAILY', 1, 0, '', 'ACTIVE', ${_s(created)}, ${_s(day)})",
    );
    await run(
      "INSERT INTO habit_completions (id, habit_id, completion_date) VALUES "
      "(1, 7, ${_s(day)}), (2, 5, ${_s(day)}), (3, 7, ${_s(day) + 86400})",
    );
    await run(
      "INSERT INTO streaks (id, name, count, max_streak, last_updated) VALUES "
      "(1, 'Sin azúcar', 3, 3, ${_s(created)})",
    );
    await run(
      "INSERT INTO streak_history_entries (id, streak_id, count, reached_at) "
      "VALUES (9, 1, 3, ${_s(day)})",
    );
    // The child project has the lower id: it was created first and moved.
    await run(
      "INSERT INTO projects (id, name, parent_id) VALUES "
      "(2, 'Raíz', NULL), (1, 'Hijo', 2), (3, 'Nieto', 1)",
    );
    await run(
      "INSERT INTO todo_tasks (id, title, priority, status, project_id) VALUES "
      "(1, 'En raíz', 'LOW', 'TODO', 2), (2, 'En nieto', 'HIGH', 'DONE', 3)",
    );
    await run(
      "INSERT INTO task_comments (id, task_id, content, created_at) VALUES "
      "(1, 2, 'Listo', ${_s(created)})",
    );
    await run(
      "INSERT INTO exercises (id, name) VALUES (1, 'Sentadilla'), (2, 'Remo')",
    );
    await run(
      "INSERT INTO scheduled_exercises (id, exercise_id, scheduled_date, sets, "
      "reps, completed, repeat_days, repeat_forever) VALUES "
      "(1, 2, ${_s(day)}, 4, 8, 0, '', 0)",
    );
    await run(
      "INSERT INTO medications (id, name, kind, active) VALUES "
      "(4, 'Vitamina D', 'SUPPLEMENT', 1)",
    );
    await run(
      "INSERT INTO medication_intakes (id, medication_id, date) VALUES "
      "(1, 4, ${_s(day)})",
    );
    await run(
      "INSERT INTO nutrition_goals (id, calories, protein, carbs, fat) "
      "VALUES (1, 1800, 100, 200, 60)",
    );
    await run("INSERT INTO hydration_goals (id, millilitres) VALUES (1, 2500)");
    await run(
      "INSERT INTO water_entries (id, date, millilitres) VALUES "
      "(1, ${_s(day)}, 250)",
    );
    await run(
      "INSERT INTO sleep_logs (id, hours, date) VALUES (1, 7.5, ${_s(day)})",
    );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 14);
    return db;
  }

  test('gives every row of every table a UUID and an updatedAt', () async {
    final db = await migratedFromSeededV13();

    for (final table in db.allTables) {
      final rows = await db
          .customSelect('SELECT id, updated_at FROM "${table.actualTableName}"')
          .get();
      for (final row in rows) {
        final id = row.read<String>('id');
        expect(
          isUuid(id) || id == AppDatabase.singletonId,
          isTrue,
          reason: '${table.actualTableName}: $id',
        );
        expect(row.read<int?>('updated_at'), isNotNull);
      }
    }
  });

  test('keeps every habit completion on its own habit', () async {
    final db = await migratedFromSeededV13();

    final rows = await db
        .customSelect(
          'SELECT h.name AS name, COUNT(c.id) AS n FROM habits h '
          'JOIN habit_completions c ON c.habit_id = h.id GROUP BY h.name',
        )
        .get();

    expect(
      {for (final r in rows) r.read<String>('name'): r.read<int>('n')},
      {'Leer': 1, 'Meditar': 2},
    );
  });

  test('keeps the project tree, its tasks and their comments', () async {
    final db = await migratedFromSeededV13();

    final projects = {
      for (final p in await db.select(db.projects).get()) p.name: p,
    };
    expect(projects['Raíz']!.parentId, isNull);
    expect(projects['Hijo']!.parentId, projects['Raíz']!.id);
    expect(projects['Nieto']!.parentId, projects['Hijo']!.id);

    final tasks = {
      for (final t in await db.select(db.todoTasks).get()) t.title: t,
    };
    expect(tasks['En raíz']!.projectId, projects['Raíz']!.id);
    expect(tasks['En nieto']!.projectId, projects['Nieto']!.id);

    final comment = await db.select(db.taskComments).getSingle();
    expect(comment.taskId, tasks['En nieto']!.id);
  });

  test(
    'keeps streak history, scheduled exercises and intakes attached',
    () async {
      final db = await migratedFromSeededV13();

      final streak = await db.select(db.streaks).getSingle();
      expect(
        (await db.select(db.streakHistoryEntries).getSingle()).streakId,
        streak.id,
      );

      final remo = await (db.select(
        db.exercises,
      )..where((e) => e.name.equals('Remo'))).getSingle();
      expect(
        (await db.select(db.scheduledExercises).getSingle()).exerciseId,
        remo.id,
      );

      final medication = await db.select(db.medications).getSingle();
      expect(
        (await db.select(db.medicationIntakes).getSingle()).medicationId,
        medication.id,
      );
    },
  );

  test('starts updatedAt from createdAt where the row had one', () async {
    final db = await migratedFromSeededV13();

    for (final habit in await db.select(db.habits).get()) {
      expect(habit.updatedAt, created);
    }
    expect((await db.select(db.taskComments).getSingle()).updatedAt, created);
    expect((await db.select(db.streaks).getSingle()).updatedAt, created);
  });

  test('keeps the single goal rows under the fixed singleton id', () async {
    final db = await migratedFromSeededV13();

    final goal = await db.select(db.nutritionGoals).getSingle();
    expect(goal.id, AppDatabase.singletonId);
    expect(goal.calories, 1800);
    expect(
      (await db.select(db.hydrationGoals).getSingle()).id,
      AppDatabase.singletonId,
    );
  });

  test('leaves no orphaned reference and keeps cascades working', () async {
    final db = await migratedFromSeededV13();

    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);

    final meditar = await (db.select(
      db.habits,
    )..where((h) => h.name.equals('Meditar'))).getSingle();
    await (db.delete(db.habits)..where((h) => h.id.equals(meditar.id))).go();
    expect(await db.select(db.habitCompletions).get(), hasLength(1));
  });

  test('drops the scratch id map it used', () async {
    final db = await migratedFromSeededV13();

    final leftovers = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name LIKE '%id_map%'",
        )
        .get();
    expect(leftovers, isEmpty);
  });
}

class _RawDatabase extends GeneratedDatabase {
  _RawDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 13;
}
