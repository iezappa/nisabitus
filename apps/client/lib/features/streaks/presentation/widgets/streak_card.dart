import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/streak.dart';

/// One streak as a compact tile: its name, the current count as the largest
/// figure, the record underneath, and the two buttons that move it.
///
/// The card offers one action: add to the streak. Renaming, resetting and
/// deleting live in the editor a tap on the card opens, which keeps the
/// resting state quiet.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.streak,
    required this.onIncrement,
    required this.onRename,
    super.key,
  });

  final Streak streak;
  final VoidCallback onIncrement;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        onTap: onRename,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.sm),
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
              const SizedBox(height: Gap.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${streak.count}',
                    // Still the largest thing on the card, without the
                    // empty half a card underneath it.
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: Gap.xs),
                  Text(l10n.streakDays, style: theme.textTheme.bodySmall),
                ],
              ),
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
