import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One destination in the wide navigation rail.
typedef NavDestination = (IconData icon, IconData selectedIcon, String label);

/// A floating, icons-only rail for wide layouts.
///
/// The full-height Material rail made the gradient backdrop read as two separate
/// sheets. This keeps the same destinations and accessibility labels while the
/// page wash runs under and around navigation.
class NavRail extends StatelessWidget {
  const NavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, 0, Gap.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, destination) in destinations.indexed)
                  _RailButton(
                    destination: destination,
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, selectedIcon, label) = destination;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      child: Tooltip(
        message: label,
        preferBelow: false,
        verticalOffset: 0,
        margin: const EdgeInsets.only(left: 64),
        child: Semantics(
          label: label,
          selected: selected,
          button: true,
          child: Material(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 22,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
