import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/board_column.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;
  late String task;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTodoRepository(db);
    final project = await repository.createProject('Raíz');
    task = (await repository.createTask(
      TaskDraft(title: 'Tarea', projectId: project.id),
    )).id;
  });
  tearDown(() => db.close());

  test('a task starts with no checklist', () async {
    expect(await repository.checklist(task), isEmpty);
  });

  test('lines are kept in the order they were written', () async {
    for (final line in ['Uno', 'Dos', 'Tres']) {
      await repository.addChecklistItem(task, line);
    }

    expect((await repository.checklist(task)).map((item) => item.content), [
      'Uno',
      'Dos',
      'Tres',
    ]);
  });

  test('a blank line is refused', () async {
    expect(repository.addChecklistItem(task, '   '), throwsArgumentError);
    expect(await repository.checklist(task), isEmpty);
  });

  test('ticking a line leaves the rest alone', () async {
    await repository.addChecklistItem(task, 'Uno');
    final two = await repository.addChecklistItem(task, 'Dos');

    await repository.updateChecklistItem(two.id, done: true);

    final items = await repository.checklist(task);
    expect(items.map((item) => item.done), [false, true]);
    expect(items.doneCount, 1);
    expect(items.checkedShare, 0.5);
  });

  test('rewriting a line keeps whether it was ticked', () async {
    final item = await repository.addChecklistItem(task, 'Uno');
    await repository.updateChecklistItem(item.id, done: true);

    final edited = await repository.updateChecklistItem(
      item.id,
      content: 'Uno corregido',
    );

    expect(edited.content, 'Uno corregido');
    expect(edited.done, isTrue);
  });

  test('deleting the task takes its checklist with it', () async {
    await repository.addChecklistItem(task, 'Uno');

    await repository.deleteTask(task);

    expect(await db.select(db.taskChecklistItems).get(), isEmpty);
  });

  test('an empty checklist reads as zero rather than full', () async {
    expect(const <ChecklistItem>[].checkedShare, 0);
  });
}
