import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/habit.dart';
import '../habit_labels.dart';

/// One habit as a compact row: an icon, what it is, and a circle to resolve
/// it for today.
///
/// The row itself opens the editor and a long press opens the rest of the
/// actions, which keeps the resting state quiet — the check is the only
/// thing competing for a tap.
class HabitRow extends StatelessWidget {
  const HabitRow({
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

  /// The details that fit on one muted line under the name.
  String _subtitle(AppLocalizations l10n) => [
    if (habit.category case final category? when category.isNotEmpty) category,
    l10n.frequencyName(habit.frequency),
    if (habit.showsTargetBadge(day)) l10n.habitTargetBadge(habit.targetCount),
    if (habit.frequency.supportsRepeatDays && habit.repeatDays.isNotEmpty)
      l10n.weekdayList(habit.repeatDays),
    if (habit.isFinishedOn(day) && habit.endDate != null)
      l10n.habitFinishedOn(DateFormat('dd/MM/yyyy').format(habit.endDate!)),
  ].join(' · ');

  Future<void> _showActions(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cancelled = habit.status == HabitStatus.cancelled;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.actionEdit),
              onTap: () {
                Navigator.of(sheet).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(cancelled ? Icons.undo : Icons.close),
              title: Text(cancelled ? l10n.habitRevert : l10n.habitCancel),
              onTap: () {
                Navigator.of(sheet).pop();
                cancelled ? onRevert() : onCancel();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheet).colorScheme.error,
              ),
              title: Text(l10n.actionDelete),
              onTap: () {
                Navigator.of(sheet).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheduled = habit.isScheduledOn(day);
    final cancelled = habit.status == HabitStatus.cancelled;

    return Opacity(
      // A habit that is not expected today stays visible but recedes, so the
      // shape of the routine is still readable.
      opacity: scheduled && !cancelled ? 1 : 0.55,
      child: Card(
        child: InkWell(
          onTap: onEdit,
          onLongPress: () => _showActions(context),
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Row(
              children: [
                _Glyph(category: habit.category),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: cancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(l10n),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.sm),
                _CheckCircle(
                  status: habit.status,
                  onPressed: habit.status == HabitStatus.pending
                      ? onToggle
                      : onRevert,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tinted square that gives each row a visual anchor.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.category});

  final String? category;

  /// A stable icon per category, so the same category always looks the same.
  static const _icons = [
    Icons.self_improvement,
    Icons.menu_book_outlined,
    Icons.water_drop_outlined,
    Icons.directions_run,
    Icons.bedtime_outlined,
    Icons.spa_outlined,
    Icons.lightbulb_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = category?.trim() ?? '';
    final icon = key.isEmpty
        ? Icons.check_circle_outline
        : _icons[key.hashCode.abs() % _icons.length];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: theme.colorScheme.primary),
    );
  }
}

/// The trailing circle: empty when pending, filled when resolved.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.status, required this.onPressed});

  final HabitStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final (background, border, icon, tooltip) = switch (status) {
      HabitStatus.done => (
        theme.colorScheme.primary,
        theme.colorScheme.primary,
        Icons.check,
        l10n.habitCompleted,
      ),
      HabitStatus.cancelled => (
        theme.colorScheme.error,
        theme.colorScheme.error,
        Icons.close,
        l10n.habitCancelled,
      ),
      HabitStatus.pending => (
        Colors.transparent,
        theme.colorScheme.outlineVariant,
        null,
        l10n.habitDone,
      ),
    };

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
          ),
          child: icon == null
              ? null
              : Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}
