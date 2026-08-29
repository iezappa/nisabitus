import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/streak.dart';

/// One streak as a compact tile: its name, the current count as the largest
/// figure, the record underneath, and a single button that moves it.
///
/// Reset and delete live behind a long press, so the resting card offers one
/// obvious action instead of three competing ones.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.streak,
    required this.onIncrement,
    required this.onReset,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final Streak streak;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  Future<void> _showActions(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

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
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l10n.streakReset),
              onTap: () {
                Navigator.of(sheet).pop();
                onReset();
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

    return Card(
      child: InkWell(
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                streak.name.toUpperCase(),
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Gap.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${streak.count}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: Gap.xs),
                  Text(l10n.streakDays, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: Gap.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.streakRecord(streak.maxStreak),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: l10n.streakIncrement,
                    visualDensity: VisualDensity.compact,
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
