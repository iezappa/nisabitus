import '../../../core/time/date_range.dart';

/// How urgent a task is.
enum TaskPriority {
  urgent('URGENT', 0),
  high('HIGH', 1),
  medium('MEDIUM', 2),
  low('LOW', 3);

  const TaskPriority(this.wireName, this.rank);

  final String wireName;

  /// Sort order: lower comes first, so urgent leads.
  final int rank;

  static TaskPriority parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return TaskPriority.medium;

    for (final priority in TaskPriority.values) {
      if (priority.wireName == normalized) return priority;
    }
    throw ArgumentError.value(value, 'value', 'Unknown task priority');
  }
}

/// Which column of the board a task sits in.
enum TaskStatus {
  todo('TODO'),
  inProgress('IN_PROGRESS'),
  done('DONE');

  const TaskStatus(this.wireName);

  final String wireName;

  static TaskStatus parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return TaskStatus.todo;

    for (final status in TaskStatus.values) {
      if (status.wireName == normalized) return status;
    }
    throw ArgumentError.value(value, 'value', 'Unknown task status');
  }
}

/// How a task's due date reads today.
enum DueState { none, overdue, today, upcoming }

/// A unit of work belonging to a project.
class Task {
  Task({
    required this.id,
    required String title,
    required this.projectId,
    required this.priority,
    required this.status,
    this.description,
    this.category,
    DateTime? startDate,
    DateTime? dueDate,
    this.completedAt,
    this.projectName,
  }) : title = _validateTitle(title),
       startDate = startDate == null ? null : dateOnly(startDate),
       dueDate = dueDate == null ? null : dateOnly(dueDate);

  final int id;
  final String title;
  final String? description;
  final String? category;
  final DateTime? startDate;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final int projectId;

  /// The moment the task reached DONE, or null while it is open.
  ///
  /// Kept as an instant rather than a day: the progress chart groups by day,
  /// but the ordering inside a day is worth keeping.
  final DateTime? completedAt;

  /// Set when the task was pulled in from a subproject, so the card can say
  /// where it came from.
  final String? projectName;

  static String _validateTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'title', 'The title is required');
    }
    return trimmed;
  }

  /// Where the due date stands relative to [today].
  ///
  /// A finished task is never overdue: chasing something already done helps
  /// nobody.
  DueState dueState(DateTime today) {
    final due = dueDate;
    if (due == null || status == TaskStatus.done) return DueState.none;

    final day = dateOnly(today);
    if (due.isBefore(day)) return DueState.overdue;
    if (due.isAtSameMomentAs(day)) return DueState.today;
    return DueState.upcoming;
  }
}

/// A note of progress attached to a task.
class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int taskId;
  final String content;
  final DateTime createdAt;
}
