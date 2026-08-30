import '../../../core/time/daily_point.dart';
import '../../../core/time/date_range.dart';
import 'task.dart';

/// What the to-do board says over a window.
///
/// Completions belong to the window; open and overdue describe the board as
/// it stands today. Mixing the two would be wrong in both directions: a task
/// still open was not opened "inside" a window, and a task finished last
/// month is not on the board any more.
class TodoStats {
  const TodoStats._({
    required this.completed,
    required this.open,
    required this.overdue,
    required this.perDay,
  });

  /// Reads the figures off every task, whatever project it belongs to.
  factory TodoStats.from(DateRange range, List<Task> tasks, DateTime today) {
    final completionsPerDay = <DateTime, int>{};
    var completed = 0;
    var open = 0;
    var overdue = 0;

    for (final task in tasks) {
      if (task.status != TaskStatus.done) {
        open++;
        if (task.dueState(today) == DueState.overdue) overdue++;
      }

      final stamp = task.completedAt;
      if (stamp == null || !range.contains(stamp)) continue;

      completed++;
      final day = dateOnly(stamp);
      completionsPerDay[day] = (completionsPerDay[day] ?? 0) + 1;
    }

    return TodoStats._(
      completed: completed,
      open: open,
      overdue: overdue,
      perDay: [
        for (final day in range.days)
          (day: day, value: (completionsPerDay[day] ?? 0).toDouble()),
      ],
    );
  }

  /// Tasks whose completion stamp falls inside the window.
  final int completed;

  /// Tasks not finished, as of now.
  final int open;

  /// Open tasks whose due date has already passed.
  final int overdue;

  /// Completions per day, one point for every day of the window.
  final List<DailyPoint> perDay;

  bool get isEmpty => completed == 0 && open == 0;
}
