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

/// How a task's due date reads today.
enum DueState { none, overdue, today, upcoming }

/// A unit of work belonging to a project.
class Task {
  Task({
    required this.id,
    required String title,
    required this.projectId,
    required this.priority,
    required this.columnId,
    this.countsAsDone = false,
    this.description,
    this.category,
    DateTime? startDate,
    DateTime? dueDate,
    this.completedAt,
    this.projectName,
    this.owner,
    String? boardColumnId,
  }) : title = _validateTitle(title),
       boardColumnId = boardColumnId ?? columnId,
       startDate = startDate == null ? null : dateOnly(startDate),
       dueDate = dueDate == null ? null : dateOnly(dueDate);

  final String id;
  final String title;
  final String? description;
  final String? category;
  final DateTime? startDate;
  final DateTime? dueDate;
  final TaskPriority priority;

  /// The column of the board it sits in. What that column is called, and
  /// whether it means finished, belongs to the column — see [BoardColumn].
  final String columnId;

  /// Whether the column it sits in counts as finished.
  ///
  /// Resolved when the task is read rather than stored, the same way
  /// [projectName] is: it is a fact about the column, and copying it onto
  /// the row would leave every task of a column stale the moment that column
  /// changes.
  final bool countsAsDone;

  final String projectId;

  /// The moment the task reached DONE, or null while it is open.
  ///
  /// Kept as an instant rather than a day: the progress chart groups by day,
  /// but the ordering inside a day is worth keeping.
  final DateTime? completedAt;

  /// Set when the task was pulled in from a subproject, so the card can say
  /// where it came from.
  final String? projectName;

  /// Who the task belongs to, when it belongs to someone other than the
  /// person holding the phone.
  ///
  /// A name typed by hand, not an account: this app has no accounts and is
  /// not going to grow them. It is here so a board can carry what the user
  /// is waiting on from somebody else without pretending that somebody else
  /// is ever going to open this copy of the app.
  final String? owner;

  /// Which column of the board on screen the task is drawn under.
  ///
  /// The same as [columnId] for a task on its own board. With subprojects
  /// included the board carries tasks that answer to another project's
  /// board, and their columns are other rows entirely — so grouping by
  /// [columnId] drew them nowhere and they simply vanished, which is the
  /// bug this field exists to fix. Where the task really is stays in
  /// [columnId]: that is what a move has to read.
  final String boardColumnId;

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
    if (due == null || countsAsDone) return DueState.none;

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

  final String id;
  final String taskId;
  final String content;
  final DateTime createdAt;
}
