import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/project.dart';
import 'package:nisabitus/features/todo/domain/board_column.dart';
import 'package:nisabitus/features/todo/domain/task.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTodoRepository(db);
  });
  tearDown(() => db.close());

  group('projects', () {
    test('start empty', () async {
      expect(await repository.projects(), isEmpty);
    });

    test('can be nested', () async {
      final root = await repository.createProject('Nisabitus');
      final child = await repository.createProject(
        'Módulos',
        parentId: root.id,
      );

      expect(child.parentId, root.id);
      expect(await repository.projects(), hasLength(2));
    });

    test('reject a blank name', () {
      expect(() => repository.createProject('   '), throwsArgumentError);
    });

    test('can be renamed and reparented', () async {
      final a = await repository.createProject('A');
      final b = await repository.createProject('B');

      final moved = await repository.updateProject(
        b.id,
        name: 'B renombrado',
        parentId: a.id,
      );

      expect(moved.name, 'B renombrado');
      expect(moved.parentId, a.id);
    });

    test('refuse a move that would break the tree', () async {
      final root = await repository.createProject('Raíz');
      final child = await repository.createProject('Hijo', parentId: root.id);

      // Hanging the root off its own child would cut the branch loose.
      expect(
        () =>
            repository.updateProject(root.id, name: 'Raíz', parentId: child.id),
        throwsArgumentError,
      );
    });

    test('refuse a move that would reach a fourth level', () async {
      final a = await repository.createProject('A');
      final b = await repository.createProject('B', parentId: a.id);
      final c = await repository.createProject('C');
      await repository.createProject('D', parentId: c.id);

      expect(
        () => repository.updateProject(c.id, name: 'C', parentId: b.id),
        throwsArgumentError,
      );
    });

    test('deleting one takes its subprojects and tasks with it', () async {
      final root = await repository.createProject('Raíz');
      final child = await repository.createProject('Hijo', parentId: root.id);
      await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: child.id),
      );

      await repository.deleteProject(root.id);

      expect(await repository.projects(), isEmpty);
      expect(await repository.tasks(child.id), isEmpty);
    });
  });

  group('tasks', () {
    late Project root;
    late Project child;

    setUp(() async {
      root = await repository.createProject('Raíz');
      child = await repository.createProject('Hijo', parentId: root.id);
    });

    test('belong to the project they were filed under', () async {
      await repository.createTask(
        TaskDraft(title: 'Directa', projectId: root.id),
      );
      await repository.createTask(
        TaskDraft(title: 'Anidada', projectId: child.id),
      );

      final direct = await repository.tasks(root.id);

      expect(direct.map((t) => t.title), ['Directa']);
    });

    test('can be pulled in from the subprojects', () async {
      await repository.createTask(
        TaskDraft(title: 'Directa', projectId: root.id),
      );
      await repository.createTask(
        TaskDraft(title: 'Anidada', projectId: child.id),
      );

      final all = await repository.tasks(root.id, includeDescendants: true);

      expect(all.map((t) => t.title), containsAll(['Directa', 'Anidada']));
    });

    test('are drawn under a column of the board on screen', () async {
      // The bug this exists for: a task pulled in from a subproject sits in
      // a column of its OWN board, and those are different rows. Grouped by
      // the id it carries, it belonged to no column on screen and the board
      // simply did not draw it — the switch looked broken.
      await repository.createTask(
        TaskDraft(title: 'Anidada', projectId: child.id),
      );

      final pulled = (await repository.tasks(
        root.id,
        includeDescendants: true,
      )).single;
      final board = Board(await repository.boardColumns(root.id));

      expect(board.byId(pulled.columnId), isNull, reason: 'not this board');
      expect(board.byId(pulled.boardColumnId), isNotNull);
      expect(
        board.byId(pulled.boardColumnId)!.builtInKey,
        BoardColumn.todoKey,
        reason: 'the column that means the same',
      );
    });

    test('are drawn under the column that means the same, renamed', () async {
      // Matched on the folded name once the user has renamed both, which is
      // the only thing two boards can still have in common.
      final board = Board(await repository.boardColumns(child.id));
      await repository.updateColumn(
        board.columns.last.id,
        name: 'Listo',
        countsAsDone: true,
      );
      final rootBoard = Board(await repository.boardColumns(root.id));
      await repository.updateColumn(
        rootBoard.columns.last.id,
        name: 'listo',
        countsAsDone: true,
      );

      final moved = await repository.createTask(
        TaskDraft(title: 'Anidada', projectId: child.id),
      );
      await repository.moveTask(moved.id, board.columns.last.id);

      final pulled = (await repository.tasks(
        root.id,
        includeDescendants: true,
      )).single;

      expect(
        pulled.boardColumnId,
        (await repository.boardColumns(root.id)).last.id,
      );
    });

    test('stay where they really are, whatever the board shows', () async {
      // `boardColumnId` is for drawing; a move has to read the real one.
      await repository.createTask(
        TaskDraft(title: 'Anidada', projectId: child.id),
      );

      final pulled = (await repository.tasks(
        root.id,
        includeDescendants: true,
      )).single;
      final own = Board(await repository.boardColumns(child.id));

      expect(own.byId(pulled.columnId), isNotNull);
    });

    test('carry the name of the subproject they came from', () async {
      await repository.createTask(
        TaskDraft(title: 'Anidada', projectId: child.id),
      );

      final all = await repository.tasks(root.id, includeDescendants: true);

      expect(all.single.projectName, 'Hijo');
    });

    test('default to a pending medium priority', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: root.id),
      );

      // No column named, so it lands in the board's default: the leftmost
      // one that does not already mean finished.
      final board = Board(await repository.boardColumns(root.id));
      expect(task.columnId, board.defaultColumn!.id);
      expect(task.countsAsDone, isFalse);
      expect(task.priority, TaskPriority.medium);
    });

    test('reject a blank title', () {
      expect(
        () => repository.createTask(TaskDraft(title: ' ', projectId: root.id)),
        throwsArgumentError,
      );
    });

    test('move between columns', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: root.id),
      );

      final done = (await repository.boardColumns(root.id))
          .firstWhere((column) => column.builtInKey == BoardColumn.doneKey);

      final moved = await repository.moveTask(task.id, done.id);

      expect(moved.columnId, done.id);
      expect(moved.countsAsDone, isTrue);
    });

    test('can be edited and deleted', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: root.id),
      );

      await repository.updateTask(
        task.id,
        TaskDraft(
          title: 'Tarea editada',
          projectId: root.id,
          priority: TaskPriority.urgent,
        ),
      );
      final edited = (await repository.tasks(root.id)).single;
      expect(edited.title, 'Tarea editada');
      expect(edited.priority, TaskPriority.urgent);

      await repository.deleteTask(task.id);
      expect(await repository.tasks(root.id), isEmpty);
    });
  });

  group('counts', () {
    test('report the tasks filed directly on each project', () async {
      final root = await repository.createProject('Raíz');
      final child = await repository.createProject('Hijo', parentId: root.id);
      await repository.createTask(TaskDraft(title: 'A', projectId: root.id));
      await repository.createTask(TaskDraft(title: 'B', projectId: child.id));
      await repository.createTask(TaskDraft(title: 'C', projectId: child.id));

      final counts = await repository.directTaskCounts();

      expect(counts[root.id], 1);
      expect(counts[child.id], 2);
    });
  });

  group('comments', () {
    test('are listed oldest first', () async {
      final project = await repository.createProject('Raíz');
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project.id),
      );

      await repository.addComment(task.id, 'Primero');
      await repository.addComment(task.id, 'Segundo');

      final comments = await repository.comments(task.id);
      expect(comments.map((c) => c.content), ['Primero', 'Segundo']);
    });

    test('go away with their task', () async {
      final project = await repository.createProject('Raíz');
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project.id),
      );
      await repository.addComment(task.id, 'Nota');

      await repository.deleteTask(task.id);

      expect(await repository.comments(task.id), isEmpty);
    });

    test('can be removed one at a time', () async {
      final project = await repository.createProject('Raíz');
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project.id),
      );
      final comment = await repository.addComment(task.id, 'Nota');

      await repository.deleteComment(comment.id);

      expect(await repository.comments(task.id), isEmpty);
    });

    test('reject blank content', () async {
      final project = await repository.createProject('Raíz');
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project.id),
      );

      expect(() => repository.addComment(task.id, '  '), throwsArgumentError);
    });
  });

  group('statsFor', () {
    final march = DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));

    test('reads as empty before there is any task', () async {
      expect((await repository.statsFor(march)).isEmpty, isTrue);
    });

    test('counts what is open and what is overdue today', () async {
      final project = await repository.createProject('Raíz');
      await repository.createTask(
        TaskDraft(
          title: 'Vencida',
          projectId: project.id,
          dueDate: DateTime(2026, 3, 1),
        ),
      );
      await repository.createTask(
        TaskDraft(
          title: 'A tiempo',
          projectId: project.id,
          dueDate: DateTime(2026, 3, 31),
        ),
      );

      final stats = await repository.statsFor(
        march,
        today: DateTime(2026, 3, 15),
      );

      expect(stats.open, 2);
      expect(stats.overdue, 1);
      expect(stats.completed, 0);
    });

    test('counts a finished task on the day it was finished', () async {
      final project = await repository.createProject('Raíz');
      final task = await repository.createTask(
        TaskDraft(title: 'Hecha', projectId: project.id),
      );

      await repository.moveTask(
        task.id,
        (await repository.boardColumns(project.id))
            .firstWhere((column) => column.builtInKey == BoardColumn.doneKey)
            .id,
      );

      final stats = await repository.statsFor(
        DateRange.lastDays(7),
        today: DateTime.now(),
      );

      expect(stats.completed, 1);
      expect(stats.open, 0);
      expect(stats.perDay.last.value, 1);
    });
  });

  group('owners', () {
    late Project project;

    setUp(() async {
      project = await repository.createProject('Casa');
    });

    test('are nobody until one is named', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: project.id),
      );

      expect(task.owner, isNull, reason: 'the user\'s own');
      expect(await repository.owners(), isEmpty);
    });

    test('are written down and read back', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Firmar', projectId: project.id, owner: 'Ana'),
      );

      expect(task.owner, 'Ana');
      expect((await repository.tasks(project.id)).single.owner, 'Ana');
    });

    test('are offered once, however many tasks carry them', () async {
      for (final owner in ['Ana', 'Ana', 'Bruno']) {
        await repository.createTask(
          TaskDraft(title: 'Tarea', projectId: project.id, owner: owner),
        );
      }

      expect(await repository.owners(), ['Ana', 'Bruno']);
    });

    test('are sorted the way Spanish reads', () async {
      for (final owner in ['Zoe', 'Ángela', 'Bruno']) {
        await repository.createTask(
          TaskDraft(title: 'Tarea', projectId: project.id, owner: owner),
        );
      }

      expect(await repository.owners(), ['Ángela', 'Bruno', 'Zoe']);
    });

    test('stop being offered once nothing is assigned to them', () async {
      // There is no list of people in this app, only the names on tasks.
      final task = await repository.createTask(
        TaskDraft(title: 'Firmar', projectId: project.id, owner: 'Ana'),
      );

      await repository.deleteTask(task.id);

      expect(await repository.owners(), isEmpty);
    });

    test('are cleared by saving the task without one', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Firmar', projectId: project.id, owner: 'Ana'),
      );

      await repository.updateTask(
        task.id,
        TaskDraft(title: 'Firmar', projectId: project.id),
      );

      expect((await repository.tasks(project.id)).single.owner, isNull);
    });
  });
}
