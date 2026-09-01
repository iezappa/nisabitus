import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/task.dart';
import '../todo_labels.dart';

/// One task, on the board or in the list.
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Task task;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final due = task.dueState(today);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: task.status == TaskStatus.done
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              if (task.description case final text? when text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    text,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Pill(
                    label: l10n.priorityName(task.priority),
                    colour: priorityColor(context, task.priority),
                  ),
                  if (task.category case final c? when c.isNotEmpty)
                    Text(c, style: theme.textTheme.bodySmall),
                  if (task.dueDate case final date?)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: dueColor(context, due),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          DateFormat('dd/MM').format(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: dueColor(context, due),
                          ),
                        ),
                      ],
                    ),
                  // Only present when the task was pulled in from a
                  // subproject, so the board says where it actually lives.
                  if (task.projectName case final name?)
                    _Pill(label: name, colour: theme.colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: colour),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: colour, letterSpacing: 0.4),
    ),
  );
}
