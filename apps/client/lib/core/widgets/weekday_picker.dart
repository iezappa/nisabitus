import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../time/weekday.dart';
import '../time/weekday_labels.dart';

/// Picks the days of the week something repeats on.
///
/// In `core/` beside the enum and its labels: habits repeat on weekdays and
/// so does training, and a second row of chips somewhere else would be a
/// second shape for the same question — which is exactly how one screen ends
/// up with round chips and another with square ticked ones.
///
/// Round, and with no checkmark: the day is one or two letters, and a tick
/// crammed next to it makes a chip that is wider than the word it holds.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<Weekday> selected;
  final ValueChanged<Set<Weekday>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final day in Weekday.values)
          ChoiceChip(
            shape: const CircleBorder(),
            showCheckmark: false,
            label: SizedBox(
              width: 16,
              child: Center(
                child: Text(
                  l10n.weekdayShort(day),
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
            selected: selected.contains(day),
            onSelected: (isSelected) => onChanged(
              {...selected, if (isSelected) day}
                ..removeWhere((value) => !isSelected && value == day),
            ),
          ),
      ],
    );
  }
}
