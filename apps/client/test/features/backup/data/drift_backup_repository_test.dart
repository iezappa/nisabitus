import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/features/backup/data/drift_backup_repository.dart';
import 'package:nisabit/features/backup/domain/backup_document.dart';
import 'package:nisabit/features/backup/domain/backup_repository.dart';
import 'package:nisabit/features/habits/data/drift_habit_repository.dart';
import 'package:nisabit/features/habits/domain/habit_draft.dart';
import 'package:nisabit/features/habits/domain/habit_frequency.dart';
import 'package:nisabit/features/todo/data/drift_todo_repository.dart';
import 'package:nisabit/features/todo/domain/todo_repository.dart';

void main() {
  late AppDatabase db;
  late BackupRepository repository;
  late TodoRepository todo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftBackupRepository(db);
    todo = DriftTodoRepository(db);
  });
  tearDown(() => db.close());

  Future<void> seed() async {
    final habits = DriftHabitRepository(db);
    await habits.create(
      const HabitDraft(name: 'Meditar', frequency: HabitFrequency.daily),
    );

    final project = await todo.createProject('Nísabit');
    final task = await todo.createTask(
      TaskDraft(title: 'Exportar', projectId: project.id),
    );
    await todo.addComment(task.id, 'En ello');
  }

  group('export', () {
    test('carries every table of the database, empty ones included', () async {
      final document = await repository.export();

      // The assertion that matters: a table added later and forgotten here
      // would leave a hole in every backup, and nobody would notice until a
      // restore came back short.
      expect(
        document.tables.keys.toSet(),
        db.allTables.map((table) => table.actualTableName).toSet(),
      );
    });

    test('stamps the schema the rows were taken from', () async {
      expect((await repository.export()).schemaVersion, db.schemaVersion);
    });

    test('carries the rows that were written', () async {
      await seed();

      final document = await repository.export();

      expect(document.tables['habits'], hasLength(1));
      expect(document.tables['habits']!.single['name'], 'Meditar');
      expect(document.tables['projects'], hasLength(1));
      expect(document.tables['todo_tasks'], hasLength(1));
      expect(document.tables['task_comments'], hasLength(1));
    });

    test('survives a round trip through its own text', () async {
      await seed();

      final restored = BackupDocument.parse(
        (await repository.export()).encode(),
        supportedSchemaVersion: db.schemaVersion,
      );

      expect(restored.tables['habits']!.single['name'], 'Meditar');
    });
  });

  group('restore', () {
    test('puts back what the document holds', () async {
      await seed();
      final document = await repository.export();

      await db.delete(db.habits).go();
      await repository.restore(document);

      expect(await db.select(db.habits).get(), hasLength(1));
    });

    test('replaces what is there rather than merging into it', () async {
      final empty = await repository.export();
      await seed();

      await repository.restore(empty);

      // The document was taken from an empty store, so restoring it empties
      // this one. Anything else would leave the user with a store that
      // matches neither the backup nor what they had.
      expect(await db.select(db.habits).get(), isEmpty);
      expect(await db.select(db.projects).get(), isEmpty);
    });

    test('does not pile up duplicates when restored twice', () async {
      await seed();
      final document = await repository.export();

      await repository.restore(document);
      await repository.restore(document);

      expect(await db.select(db.habits).get(), hasLength(1));
    });

    test('keeps the ids, so the references still point somewhere', () async {
      await seed();
      final document = await repository.export();
      final before = await db.select(db.todoTasks).getSingle();

      await repository.restore(document);

      final after = await db.select(db.todoTasks).getSingle();
      expect(after.id, before.id);
      expect(after.projectId, before.projectId);
      expect((await db.select(db.taskComments).getSingle()).taskId, after.id);
    });

    test('restores a project moved under one created after it', () async {
      // Inserting by id would put the child before its parent and trip the
      // foreign key, so the projects have to be ordered by the tree.
      final first = await todo.createProject('Primero');
      final second = await todo.createProject('Segundo');
      await todo.updateProject(first.id, name: 'Primero', parentId: second.id);
      final document = await repository.export();

      await repository.restore(document);

      final rows = await db.select(db.projects).get();
      expect(rows, hasLength(2));
      expect(rows.firstWhere((row) => row.id == first.id).parentId, second.id);
    });

    test('leaves the store untouched when a row cannot be written', () async {
      await seed();
      final document = await repository.export();
      final broken = BackupDocument(
        schemaVersion: document.schemaVersion,
        exportedAt: document.exportedAt,
        tables: {
          ...document.tables,
          // A comment against a task that is not in the document.
          'task_comments': [
            {'id': 99, 'taskId': 4242, 'content': 'Huérfano', 'createdAt': 0},
          ],
        },
      );

      await expectLater(repository.restore(broken), throwsA(isA<Object>()));

      // All or nothing: a half restored store is worse than no restore.
      expect(await db.select(db.habits).get(), hasLength(1));
      expect(await db.select(db.taskComments).get(), hasLength(1));
      expect((await db.select(db.taskComments).getSingle()).content, 'En ello');
    });

    test('fills a column the backup predates with its default', () async {
      await seed();
      final document = await repository.export();
      final older = BackupDocument(
        schemaVersion: 3,
        exportedAt: document.exportedAt,
        tables: {
          ...document.tables,
          'todo_tasks': [
            for (final row in document.tables['todo_tasks']!)
              {...row}..remove('completedAt'),
          ],
        },
      );

      await repository.restore(older);

      expect((await db.select(db.todoTasks).getSingle()).completedAt, isNull);
    });

    test('ignores a table the document does not mention', () async {
      await seed();
      final document = await repository.export();
      final partial = BackupDocument(
        schemaVersion: document.schemaVersion,
        exportedAt: document.exportedAt,
        tables: {...document.tables}..remove('habits'),
      );

      await repository.restore(partial);

      // Nothing was said about habits, so nothing is claimed about them:
      // the restore still clears the table, because the document is the
      // whole truth about the store it describes.
      expect(await db.select(db.habits).get(), isEmpty);
    });
  });
}
