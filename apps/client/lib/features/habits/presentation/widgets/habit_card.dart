import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/habit.dart';
import '../habit_labels.dart';

/// One habit in the list, with the actions that resolve it for today.
///
/// A habit that is not expected today is dimmed rather than hidden, so the
/// user still sees the full shape of their routine.
class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.habit,
    required this.day,
    required this.onToggle,
    required this.onCancel,
    required this.onRevert,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Habit habit;
  final DateTime day;
  final VoidCallback onToggle;
  final VoidCallback onCancel;
  final VoidCallback onRevert;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheduled = habit.isScheduledOn(day);
    final resolved = habit.status != HabitStatus.pending;

    return Opacity(
      opacity: scheduled ? 1 : 0.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (habit.category case final category?
                            when category.isNotEmpty)
                          Text(
                            category.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        Text(habit.name, style: theme.textTheme.titleMedium),
                        if (habit.description case final description?
                            when description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: onEdit,
                        child: Text(l10n.actionEdit),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: onDelete,
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                    builder: (context, controller, _) => IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                    ),
                  ),
                ],
              ),
              _Badges(habit: habit, day: day),
              const SizedBox(height: 8),
              if (resolved)
                _ResolvedChip(status: habit.status, onRevert: onRevert)
              else
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onToggle,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.habitDone),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(l10n.habitCancel),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.habit, required this.day});

  final Habit habit;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final labels = <String>[
      if (habit.isFinishedOn(day) && habit.endDate != null)
        l10n.habitFinishedOn(DateFormat('dd/MM/yyyy').format(habit.endDate!)),
      if (!habit.isFinishedOn(day) &&
          habit.frequency.supportsRepeatDays &&
          habit.repeatDays.isNotEmpty)
        l10n.habitScheduledOn(l10n.weekdayList(habit.repeatDays)),
      if (habit.showsTargetBadge(day)) l10n.habitTargetBadge(habit.targetCount),
    ];

    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final label in labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(label, style: theme.textTheme.labelSmall),
            ),
        ],
      ),
    );
  }
}

class _ResolvedChip extends StatelessWidget {
  const _ResolvedChip({required this.status, required this.onRevert});

  final HabitStatus status;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final done = status == HabitStatus.done;

    // Tapping the chip is how a resolved habit goes back to pending.
    return ActionChip(
      avatar: Icon(
        done ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: done ? theme.colorScheme.primary : theme.colorScheme.error,
      ),
      label: Text(done ? l10n.habitCompleted : l10n.habitCancelled),
      onPressed: onRevert,
    );
  }
}
