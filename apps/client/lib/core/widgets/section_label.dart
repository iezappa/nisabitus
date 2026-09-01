import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The uppercase label that opens a section of a flat settings column.
///
/// It carries its own trailing gap and nothing else: a section is the label
/// followed directly by its controls, and the page gutter — not the label —
/// is what holds them off the edge. Adding horizontal padding here would
/// double the gutter on a layout that has no cards to sit inside.
///
/// Shared across the Zyreth apps, so Ajustes reads the same in all of them.
/// [SectionHeader] is the app's own heavier heading, used inside the modules
/// where a section can carry a trailing action.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
