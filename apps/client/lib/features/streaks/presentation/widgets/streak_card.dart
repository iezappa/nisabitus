import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/streak.dart';

/// One streak: its name, the big current count, and the two actions that
/// move it.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.streak,
    required this.onIncrement,
    required this.onReset,
    required this.onDelete,
    super.key,
  });

  final Streak streak;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    streak.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: l10n.actionDelete,
                  onPressed: onDelete,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${streak.count}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.streakDays,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              l10n.streakRecord(streak.maxStreak),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: onIncrement,
                  child: Text(l10n.streakIncrement),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onReset,
                  child: Text(l10n.streakReset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
