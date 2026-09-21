import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/board_column.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;
  // A board belongs to a project as of v16, and creating one seeds it.
  late String project;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTodoRepository(db);
    project = (await repository.createProject('Raíz')).id;
  });
  tearDown(() => db.close());

  Future<BoardColumn> columnFor(String key) async =>
      (await repository.boardColumns(project))
          .firstWhere((column) => column.builtInKey == key);

  group('the seeded board', () {
    test('is the three columns the app ships, in order', () async {
      final columns = await repository.boardColumns(project);

      expect(columns.map((column) => column.builtInKey), [
        BoardColumn.todoKey,
        BoardColumn.inProgressKey,
        BoardColumn.doneKey,
      ]);
      expect(columns.map((column) => column.position), [0, 1, 2]);
    });

    test('finishes work in exactly one of them', () async {
      final columns = await repository.boardColumns(project);

      expect(columns.where((column) => column.countsAsDone), hasLength(1));
      expect(
        columns.firstWhere((column) => column.countsAsDone).builtInKey,
        BoardColumn.doneKey,
      );
    });
  });

  group('editing the board', () {
    test('appends a new column to the right', () async {
      final created = await repository.createColumn(project, 'Bloqueada');

      expect(created.position, 3);
      expect(created.builtInKey, isNull);
      expect((await repository.boardColumns(project)).last.id, created.id);
    });

    test('renaming a shipped column makes it the user own', () async {
      // The key is what makes the shipped three follow the app's language.
      // Once the user has named one, translating over their word would read
      // as the app throwing it away.
      final todo = await columnFor(BoardColumn.todoKey);

      final renamed = await repository.updateColumn(
        todo.id,
        name: 'Backlog',
        countsAsDone: false,
      );

      expect(renamed.name, 'Backlog');
      expect(renamed.builtInKey, isNull);
    });

    test('leaving the name alone keeps the column shipped', () async {
      final todo = await columnFor(BoardColumn.todoKey);

      final same = await repository.updateColumn(
        todo.id,
        name: todo.name,
        countsAsDone: false,
      );

      expect(same.builtInKey, BoardColumn.todoKey);
    });

    test('reorders the board by writing the whole order', () async {
      final columns = await repository.boardColumns(project);
      final ids = [columns[2].id, columns[0].id, columns[1].id];

      await repository.reorderColumns(ids);

      expect((await repository.boardColumns(project)).map((c) => c.id), ids);
    });

    test('refuses to drop a column that still holds tasks', () async {
      await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project),
      );
      final todo = await columnFor(BoardColumn.todoKey);

      expect(repository.deleteColumn(todo.id), throwsStateError);
      expect(await repository.boardColumns(project), hasLength(3));
    });

    test('drops an empty column', () async {
      final todo = await columnFor(BoardColumn.todoKey);

      await repository.deleteColumn(todo.id);

      expect(await repository.boardColumns(project), hasLength(2));
    });

    test('refuses to drop the last column standing', () async {
      for (final key in [BoardColumn.todoKey, BoardColumn.inProgressKey]) {
        await repository.deleteColumn((await columnFor(key)).id);
      }

      final last = (await repository.boardColumns(project)).single;
      expect(repository.deleteColumn(last.id), throwsStateError);
    });
  });

  group('what a column means', () {
    test('a task lands in the first column that is not finished', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project),
      );

      expect(task.columnId, (await columnFor(BoardColumn.todoKey)).id);
      expect(task.countsAsDone, isFalse);
    });

    test('a task named for a column that is gone is refused', () async {
      // Guessing would file it somewhere nobody chose.
      expect(
        repository.createTask(
          TaskDraft(
            title: 'Tarea',
            projectId: project,
            columnId: 'no-such-column',
          ),
        ),
        throwsArgumentError,
      );
    });

    test(
      'turning a column into a finishing one stamps what sits in it',
      () async {
        final task = await repository.createTask(
          TaskDraft(title: 'Tarea', projectId: project),
        );
        final todo = await columnFor(BoardColumn.todoKey);

        await repository.updateColumn(
          todo.id,
          name: todo.name,
          countsAsDone: true,
        );

        final row = await (db.select(
          db.todoTasks,
        )..where((t) => t.id.equals(task.id))).getSingle();
        expect(row.completedAt, isNotNull);
      },
    );

    test('turning it back clears them', () async {
      final done = await columnFor(BoardColumn.doneKey);
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project, columnId: done.id),
      );

      await repository.updateColumn(
        done.id,
        name: done.name,
        countsAsDone: false,
      );

      final row = await (db.select(
        db.todoTasks,
      )..where((t) => t.id.equals(task.id))).getSingle();
      expect(row.completedAt, isNull);
    });

    test(
      'moving between two finishing columns keeps the first moment',
      () async {
        // It was not finished twice.
        final done = await columnFor(BoardColumn.doneKey);
        final delivered = await repository.createColumn(
          project,
          'Entregado',
          countsAsDone: true,
        );
        final task = await repository.createTask(
          TaskDraft(title: 'Tarea', projectId: project, columnId: done.id),
        );
        final first = (await (db.select(
          db.todoTasks,
        )..where((t) => t.id.equals(task.id))).getSingle()).completedAt;

        await repository.moveTask(task.id, delivered.id);

        final row = await (db.select(
          db.todoTasks,
        )..where((t) => t.id.equals(task.id))).getSingle();
        expect(row.completedAt, first);
      },
    );
  });
}
