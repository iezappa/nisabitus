import 'package:flutter/material.dart';

import '../l10n/date_labels.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../time/date_range.dart';

/// The strip of days that decides which day is being read and written.
///
/// The selected day is not necessarily today: the sleep and journal screens
/// let the user fill in a day they missed. Days after today are disabled —
/// there is nothing to record about a night that has not happened.
class WeekDateSelector extends StatelessWidget {
  const WeekDateSelector({
    required this.selected,
    required this.onSelected,
    this.today,
    super.key,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  /// Injectable so tests are not tied to the machine clock.
  final DateTime? today;

  /// Monday of the week holding [selected].
  DateTime get _weekStart {
    final day = dateOnly(selected);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _shiftWeek(int weeks) =>
      onSelected(_weekStart.add(Duration(days: weeks * 7)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = dateOnly(today ?? DateTime.now());
    final start = _weekStart;
    final selectedDay = dateOnly(selected);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.weekPrevious,
            onPressed: () => _shiftWeek(-1),
          ),
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = start.add(Duration(days: i));
                  return _DayCell(
                    day: day,
                    isSelected: day == selectedDay,
                    isToday: day == now,
                    // A night that has not happened cannot be logged.
                    isEnabled: !day.isAfter(now),
                    onTap: () => onSelected(day),
                  );
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.weekNext,
            // Moving past the week holding today would show only dead cells.
            onPressed: start.add(const Duration(days: 7)).isAfter(now)
                ? null
                : () => _shiftWeek(1),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final foreground = switch ((isSelected, isEnabled)) {
      (true, _) => theme.colorScheme.onPrimary,
      (false, false) => theme.colorScheme.outlineVariant,
      (false, true) => theme.colorScheme.onSurface,
    };

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.weekdayLetter(day),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isEnabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: Gap.xs),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                // Today keeps a ring when it is not the selected day, so the
                // user never loses their place in the week.
                border: !isSelected && isToday
                    ? Border.all(color: theme.colorScheme.primary)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
