import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/dashboard/domain/task_focus.dart';
import 'package:nisabitus/features/todo/domain/task.dart';

void main() {
  final today = DateTime(2026, 3, 11);
  var nextId = 0;

  Task task({
    required String title,
    DateTime? due,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
  }) => Task(
    id: ++nextId,
    title: title,
    projectId: 1,
    priority: priority,
    status: status,
    dueDate: due,
  );

  List<String> titles(List<Task> tasks) =>
      tasks.map((task) => task.title).toList();

  group('grouping', () {
    test('puts the overdue first, then today, then future, then undated', () {
      final ranked = TaskFocus.rank([
        task(title: 'Sin fecha'),
        task(title: 'Futura', due: DateTime(2026, 3, 20)),
        task(title: 'Hoy', due: today),
        task(title: 'Vencida', due: DateTime(2026, 3, 1)),
      ], today);

      expect(titles(ranked), ['Vencida', 'Hoy', 'Futura', 'Sin fecha']);
    });

    test('orders two overdue tasks by how late they are', () {
      final ranked = TaskFocus.rank([
        task(title: 'Menos vencida', due: DateTime(2026, 3, 10)),
        task(title: 'Más vencida', due: DateTime(2026, 3, 1)),
      ], today);

      expect(titles(ranked), ['Más vencida', 'Menos vencida']);
    });
  });

  group('ties', () {
    test('break on priority when the dates match', () {
      final ranked = TaskFocus.rank([
        task(title: 'Baja', due: today, priority: TaskPriority.low),
        task(title: 'Urgente', due: today, priority: TaskPriority.urgent),
        task(title: 'Media', due: today),
      ], today);

      expect(titles(ranked), ['Urgente', 'Media', 'Baja']);
    });

    test('break on the title when the priority matches too', () {
      final ranked = TaskFocus.rank([
        task(title: 'Zapatos', due: today),
        task(title: 'Almohada', due: today),
      ], today);

      expect(titles(ranked), ['Almohada', 'Zapatos']);
    });

    test('produce the same order twice, whatever the input order', () {
      final input = [task(title: 'B'), task(title: 'A'), task(title: 'C')];

      expect(
        titles(TaskFocus.rank(input, today)),
        titles(TaskFocus.rank(input.reversed.toList(), today)),
      );
    });
  });

  group('what it leaves out', () {
    test('finished tasks, however overdue they look', () {
      final ranked = TaskFocus.rank([
        task(
          title: 'Hecha',
          due: DateTime(2026, 1, 1),
          status: TaskStatus.done,
        ),
        task(title: 'Abierta'),
      ], today);

      expect(titles(ranked), ['Abierta']);
    });

    test('everything past the fourth line', () {
      final ranked = TaskFocus.rank([
        for (var i = 0; i < 10; i++) task(title: 'Tarea $i'),
      ], today);

      expect(ranked, hasLength(4));
    });
  });

  test('is empty when nothing is open', () {
    expect(TaskFocus.rank(const [], today), isEmpty);
  });
}
