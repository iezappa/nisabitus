import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/task.dart';

/// Words and colours for the task enums, kept at the edge so the domain
/// stays free of display concerns.
extension TodoLabels on AppLocalizations {
  String statusName(TaskStatus status) => switch (status) {
    TaskStatus.todo => todoStatusTodo,
    TaskStatus.inProgress => todoStatusInProgress,
    TaskStatus.done => todoStatusDone,
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

Color dueColor(BuildContext context, DueState state) {
  final scheme = Theme.of(context).colorScheme;

  return switch (state) {
    DueState.overdue => scheme.error,
    DueState.today => const Color(0xFFB08A2E),
    _ => scheme.onSurfaceVariant,
  };
}
