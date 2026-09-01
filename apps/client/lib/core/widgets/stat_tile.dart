import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single figure with its label above and an optional note below.
///
/// The label is the small tracked uppercase style; the figure is the largest
/// thing in the tile, because the number is what the user came to read.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.emphasize = false,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  /// Renders the figure in the accent colour, for the one tile that matters
  /// most in a group.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: emphasize ? theme.colorScheme.primary : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (caption != null) ...[
              const SizedBox(height: Gap.xs),
              Text(
                caption!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
