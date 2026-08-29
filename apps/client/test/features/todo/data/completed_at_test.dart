import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/features/todo/data/drift_todo_repository.dart';
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

  Future<int> newTask() async {
    final project = await repository.createProject('Raíz');
    final task = await repository.createTask(
      TaskDraft(title: 'Tarea', projectId: project.id),
    );
    return task.id;
  }

  Future<DateTime?> stampOf(int id) async {
    final row = await (db.select(
      db.todoTasks,
    )..where((t) => t.id.equals(id))).getSingle();
    return row.completedAt;
  }

  group('the completion stamp', () {
    test('is absent while the task is open', () async {
      expect(await stampOf(await newTask()), isNull);
    });

    test('is written when the task reaches done', () async {
      final id = await newTask();

      await repository.setTaskStatus(id, TaskStatus.done);

      expect(await stampOf(id), isNotNull);
    });

    test('is cleared when the task is reopened', () async {
      final id = await newTask();
      await repository.setTaskStatus(id, TaskStatus.done);

      await repository.setTaskStatus(id, TaskStatus.inProgress);

      // Reopening takes the task back off the chart it was counted on.
      expect(await stampOf(id), isNull);
    });

    test('survives an edit that leaves the status alone', () async {
      final id = await newTask();
      await repository.setTaskStatus(id, TaskStatus.done);
      final original = await stampOf(id);

      final project = (await repository.projects()).first;
      await repository.updateTask(
        id,
        TaskDraft(
          title: 'Tarea renombrada',
          projectId: project.id,
          status: TaskStatus.done,
        ),
      );

      expect(await stampOf(id), original);
    });

    test('is written by an edit that finishes the task', () async {
      final id = await newTask();
      final project = (await repository.projects()).first;

      await repository.updateTask(
        id,
        TaskDraft(
          title: 'Tarea',
          projectId: project.id,
          status: TaskStatus.done,
        ),
      );

      expect(await stampOf(id), isNotNull);
    });

    test('is present from the start on a task created as done', () async {
      final project = await repository.createProject('Raíz');

      final task = await repository.createTask(
        TaskDraft(
          title: 'Ya hecha',
          projectId: project.id,
          status: TaskStatus.done,
        ),
      );

      expect(await stampOf(task.id), isNotNull);
    });
  });
}
