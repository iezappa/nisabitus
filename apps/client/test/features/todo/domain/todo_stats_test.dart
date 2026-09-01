import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/todo/domain/task.dart';
import 'package:nisabitus/features/todo/domain/todo_stats.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 12));
  final today = DateTime(2026, 3, 12);

  Task task({
    int id = 1,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
    DateTime? completedAt,
  }) => Task(
    id: id,
    title: 'Tarea',
    projectId: 1,
    priority: TaskPriority.medium,
    status: status,
    dueDate: dueDate,
    completedAt: completedAt,
  );

  Task done(DateTime at, {int id = 1}) =>
      task(id: id, status: TaskStatus.done, completedAt: at);

  group('TodoStats', () {
    test('reads as empty when there are no tasks at all', () {
      final stats = TodoStats.from(range, const [], today);

      expect(stats.isEmpty, isTrue);
    });

    test('counts what was finished inside the window', () {
      final stats = TodoStats.from(range, [
        done(DateTime(2026, 3, 10), id: 1),
        done(DateTime(2026, 3, 12), id: 2),
        done(DateTime(2026, 2, 1), id: 3),
      ], today);

      expect(stats.completed, 2);
    });

    test('counts every unfinished task as open, whatever its dates', () {
      final stats = TodoStats.from(range, [
        task(id: 1),
        task(id: 2, status: TaskStatus.inProgress),
        done(DateTime(2026, 3, 10), id: 3),
      ], today);

      expect(stats.open, 2);
      expect(stats.isEmpty, isFalse);
    });

    test('counts a task overdue only while it is still open', () {
      final stats = TodoStats.from(range, [
        task(id: 1, dueDate: DateTime(2026, 3, 10)),
        task(
          id: 2,
          status: TaskStatus.done,
          dueDate: DateTime(2026, 3, 10),
          completedAt: DateTime(2026, 3, 11),
        ),
        task(id: 3, dueDate: DateTime(2026, 3, 20)),
      ], today);

      expect(stats.overdue, 1);
    });

    test('plots completions for every day of the window, ascending', () {
      final stats = TodoStats.from(range, [
        done(DateTime(2026, 3, 10), id: 1),
        done(DateTime(2026, 3, 10), id: 2),
      ], today);

      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[1].value, 2);
    });

    test('reads the day off the stamp, ignoring the time of day', () {
      final stats = TodoStats.from(range, [
        done(DateTime(2026, 3, 12, 23, 45)),
      ], today);

      expect(stats.completed, 1);
      expect(stats.perDay.last.value, 1);
    });
  });
}
