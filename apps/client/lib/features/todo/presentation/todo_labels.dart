import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/board_column.dart';
import '../domain/project.dart';
import '../domain/task.dart';

/// Words and colours for the task enums, kept at the edge so the domain
/// stays free of display concerns.
extension TodoLabels on AppLocalizations {
  /// What to call a column.
  ///
  /// A column the app seeded is shown under its translation; one the user
  /// named is shown under their word, untouched. That is the whole point of
  /// [BoardColumn.builtInKey] — see the table for why.
  String columnName(BoardColumn column) => switch (column.builtInKey) {
    BoardColumn.todoKey => todoStatusTodo,
    BoardColumn.inProgressKey => todoStatusInProgress,
    BoardColumn.doneKey => todoStatusDone,
    _ => column.name,
  };

  String projectHealthName(ProjectHealth health) => switch (health) {
    ProjectHealth.empty => todoProjectEmpty,
    ProjectHealth.allDone => todoProjectAllDone,
    ProjectHealth.open => todoProjectOpen,
    ProjectHealth.dueToday => todoProjectDueToday,
    ProjectHealth.overdue => todoProjectOverdue,
  };

  String priorityName(TaskPriority priority) => switch (priority) {
    TaskPriority.low => todoPriorityLow,
    TaskPriority.medium => todoPriorityMedium,
    TaskPriority.high => todoPriorityHigh,
    TaskPriority.urgent => todoPriorityUrgent,
  };

  String? dueName(DueState state) => switch (state) {
    DueState.none => null,
    DueState.overdue => todoDueOverdue,
    DueState.today => todoDueToday,
    DueState.upcoming => todoDueUpcoming,
  };
}

Color priorityColor(BuildContext context, TaskPriority priority) {
  final scheme = Theme.of(context).colorScheme;

  return switch (priority) {
    TaskPriority.urgent => scheme.error,
    TaskPriority.high => const Color(0xFFB08A2E),
    TaskPriority.medium => scheme.primary,
    TaskPriority.low => scheme.outline,
  };
}

/// The colour of a project's dot.
///
/// The same three the rest of the module already uses for lateness, so a red
/// dot in the tree and a red chip on a card mean the same thing. Green is the
/// only addition, and it says the opposite of all of them: nothing is left.
Color projectHealthColor(BuildContext context, ProjectHealth health) {
  final scheme = Theme.of(context).colorScheme;

  return switch (health) {
    ProjectHealth.overdue => scheme.error,
    ProjectHealth.dueToday => const Color(0xFFB08A2E),
    ProjectHealth.open => scheme.primary,
    ProjectHealth.allDone => const Color(0xFF2E7D57),
    ProjectHealth.empty => scheme.outlineVariant,
  };
}

Color dueColor(BuildContext context, DueState state) {
  final scheme = Theme.of(context).colorScheme;

  return switch (state) {
    DueState.overdue => scheme.error,
    DueState.today => const Color(0xFFB08A2E),
    _ => scheme.onSurfaceVariant,
  };
}
