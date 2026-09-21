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

  test('a new project gets a board of its own', () async {
    final first = await repository.createProject('Uno');
    final second = await repository.createProject('Dos');

    final a = await repository.boardColumns(first.id);
    final b = await repository.boardColumns(second.id);

    expect(a, hasLength(3));
    expect(b, hasLength(3));
    // Same three columns, different rows: the point of v16 is that editing
    // one board leaves the other alone.
    expect(
      a
          .map((column) => column.id)
          .toSet()
          .intersection(b.map((column) => column.id).toSet()),
      isEmpty,
    );
  });

  test('a column added to one project stays off the others', () async {
    final first = await repository.createProject('Uno');
    final second = await repository.createProject('Dos');

    await repository.createColumn(first.id, 'En revisión');

    expect(await repository.boardColumns(first.id), hasLength(4));
    expect(await repository.boardColumns(second.id), hasLength(3));
  });

  test('deleting a project takes its board with it', () async {
    final project = await repository.createProject('Uno');

    await repository.deleteProject(project.id);

    expect(await db.select(db.boardColumns).get(), isEmpty);
  });

  test('a task cannot be filed on another project board', () async {
    final first = await repository.createProject('Uno');
    final second = await repository.createProject('Dos');
    final foreign = (await repository.boardColumns(second.id)).first;

    // Dragging a subproject's task across the board on screen names a column
    // of the board being looked at, not of the task's own. It lands on its
    // own board, in the column that means the same.
    final task = await repository.createTask(
      TaskDraft(title: 'Tarea', projectId: first.id),
    );
    final moved = await repository.moveTask(task.id, foreign.id);

    final own = await repository.boardColumns(first.id);
    expect(own.map((column) => column.id), contains(moved.columnId));
    expect(
      own.firstWhere((column) => column.id == moved.columnId).builtInKey,
      foreign.builtInKey,
    );
  });

  test('a board matches a renamed column of another board by name', () async {
    final first = await repository.createProject('Uno');
    final second = await repository.createProject('Dos');
    for (final project in [first, second]) {
      await repository.createColumn(project.id, 'En revisión');
    }
    final foreign = (await repository.boardColumns(second.id))
        .firstWhere((column) => column.name == 'En revisión');

    final task = await repository.createTask(
      TaskDraft(title: 'Tarea', projectId: first.id),
    );
    final moved = await repository.moveTask(task.id, foreign.id);

    expect(
      (await repository.boardColumns(first.id))
          .firstWhere((column) => column.id == moved.columnId)
          .name,
      'En revisión',
    );
  });

  test('the default column is the first that does not finish work', () async {
    final project = await repository.createProject('Uno');
    final board = Board(await repository.boardColumns(project.id));

    expect(board.defaultColumn?.builtInKey, BoardColumn.todoKey);
  });
}
