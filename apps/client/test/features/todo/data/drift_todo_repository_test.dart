import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/time/date_range.dart';
import 'package:nisabit/features/todo/data/drift_todo_repository.dart';
import 'package:nisabit/features/todo/domain/project.dart';
import 'package:nisabit/features/todo/domain/task.dart';
import 'package:nisabit/features/todo/domain/todo_repository.dart';

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
      final root = await repository.createProject('Nísabit');
      final child = await repository.createProject('Módulos', parentId: root.id);

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
        () => repository.updateProject(root.id, name: 'Raíz', parentId: child.id),
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
      await repository.createTask(TaskDraft(title: 'Directa', projectId: root.id));
      await repository.createTask(TaskDraft(title: 'Anidada', projectId: child.id));

      final direct = await repository.tasks(root.id);

      expect(direct.map((t) => t.title), ['Directa']);
    });

    test('can be pulled in from the subprojects', () async {
      await repository.createTask(TaskDraft(title: 'Directa', projectId: root.id));
      await repository.createTask(TaskDraft(title: 'Anidada', projectId: child.id));

      final all = await repository.tasks(root.id, includeDescendants: true);

      expect(all.map((t) => t.title), containsAll(['Directa', 'Anidada']));
    });

    test('carry the name of the subproject they came from', () async {
      await repository.createTask(TaskDraft(title: 'Anidada', projectId: child.id));

      final all = await repository.tasks(root.id, includeDescendants: true);

      expect(all.single.projectName, 'Hijo');
    });

    test('default to a pending medium priority', () async {
      final task = await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: root.id),
      );

      expect(task.status, TaskStatus.todo);
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

      final moved = await repository.setTaskStatus(task.id, TaskStatus.done);

      expect(moved.status, TaskStatus.done);
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

      await repository.setTaskStatus(task.id, TaskStatus.done);

      final stats = await repository.statsFor(
        DateRange.lastDays(7),
        today: DateTime.now(),
      );

      expect(stats.completed, 1);
      expect(stats.open, 0);
      expect(stats.perDay.last.value, 1);
    });
  });
}
