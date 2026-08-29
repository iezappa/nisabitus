import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/streak.dart';

/// One streak as a compact tile: its name, the current count as the largest
/// figure, the record underneath, and the two buttons that move it.
///
/// Reset sits on the card rather than behind a gesture. A streak breaks at a
/// specific moment and the user reaches for it right then; burying that
/// action makes the app argue with them at the worst time.
///
/// Tapping the card opens its editor, where renaming and deleting live.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.streak,
    required this.onIncrement,
    required this.onReset,
    required this.onRename,
    super.key,
  });

  final Streak streak;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        onTap: onRename,
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
              Text(
                l10n.streakRecord(streak.maxStreak),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Gap.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReset,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        l10n.streakReset,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
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
