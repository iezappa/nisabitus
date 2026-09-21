import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/board_column.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTodoRepository(db);
  });
  tearDown(() => db.close());

  /// The board belongs to a project as of v16, so these tests need one to
  /// name a column of.
  Future<String> theProject() async =>
      (await repository.projects()).singleOrNull?.id ??
      (await repository.createProject('Raíz')).id;

  Future<String> newTask() async {
    final task = await repository.createTask(
      TaskDraft(title: 'Tarea', projectId: await theProject()),
    );
    return task.id;
  }

  /// The seeded column carrying [key], which is how these tests name a
  /// column now that the board is rows rather than an enum.
  Future<String> column(String key) async =>
      (await repository.boardColumns(await theProject()))
          .firstWhere((column) => column.builtInKey == key)
          .id;

  Future<DateTime?> stampOf(String id) async {
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

      await repository.moveTask(id, await column(BoardColumn.doneKey));

      expect(await stampOf(id), isNotNull);
    });

    test('is cleared when the task is reopened', () async {
      final id = await newTask();
      await repository.moveTask(id, await column(BoardColumn.doneKey));

      await repository.moveTask(id, await column(BoardColumn.inProgressKey));

      // Reopening takes the task back off the chart it was counted on.
      expect(await stampOf(id), isNull);
    });

    test('survives an edit that leaves the status alone', () async {
      final id = await newTask();
      await repository.moveTask(id, await column(BoardColumn.doneKey));
      final original = await stampOf(id);

      await repository.updateTask(
        id,
        TaskDraft(
          title: 'Tarea renombrada',
          projectId: await theProject(),
          columnId: await column(BoardColumn.doneKey),
        ),
      );

      expect(await stampOf(id), original);
    });

    test('is written by an edit that finishes the task', () async {
      final id = await newTask();

      await repository.updateTask(
        id,
        TaskDraft(
          title: 'Tarea',
          projectId: await theProject(),
          columnId: await column(BoardColumn.doneKey),
        ),
      );

      expect(await stampOf(id), isNotNull);
    });

    test('is present from the start on a task created as done', () async {
      final task = await repository.createTask(
        TaskDraft(
          title: 'Ya hecha',
          projectId: await theProject(),
          columnId: await column(BoardColumn.doneKey),
        ),
      );

      expect(await stampOf(task.id), isNotNull);
    });
  });
}
