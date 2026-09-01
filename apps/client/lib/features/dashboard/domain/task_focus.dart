import '../../todo/domain/task.dart';

/// Picks the handful of open tasks worth showing on the panel.
///
/// The order encodes what "next" means: something already late comes before
/// something due today, which comes before something in the future, which
/// comes before something with no date at all. Ties fall back to the due
/// date, then priority, then the title, so the list never reshuffles between
/// two identical loads.
abstract final class TaskFocus {
  /// How many lines the panel has room for.
  static const limit = 4;

  static List<Task> rank(
    List<Task> tasks,
    DateTime today, {
    int limit = TaskFocus.limit,
  }) {
    final open = tasks.where((task) => task.status != TaskStatus.done).toList()
      ..sort((a, b) => _compare(a, b, today));

    return open.take(limit).toList();
  }

  static int _compare(Task a, Task b, DateTime today) {
    final group = _group(a, today).compareTo(_group(b, today));
    if (group != 0) return group;

    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue != null && bDue != null) {
      final due = aDue.compareTo(bDue);
      if (due != 0) return due;
    }

    final priority = a.priority.rank.compareTo(b.priority.rank);
    if (priority != 0) return priority;

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static int _group(Task task, DateTime today) =>
      switch (task.dueState(today)) {
        DueState.overdue => 0,
        DueState.today => 1,
        DueState.upcoming => 2,
        DueState.none => 3,
      };
}
