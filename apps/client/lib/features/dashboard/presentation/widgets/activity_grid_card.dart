import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/date_labels.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/selected_day_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/activity_grid.dart';
import '../dashboard_providers.dart';

/// The contribution grid: one square per day, darker the more was recorded.
///
/// Reads as a whole before it reads in detail — the shape of the last six
/// months answers "have I kept this up" without a single square being
/// inspected. The numbers under it are there for when the answer is "not
/// really" and the user wants to know how much.
class ActivityGridCard extends ConsumerWidget {
  const ActivityGridCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final grid = ref.watch(activityGridProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: grid.when(
            // Sized like the grid it is about to become, so the panel does
            // not jump once the counts arrive.
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              '$error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (data) => _Grid(grid: data, l10n: l10n),
          ),
        ),
      ),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.grid, required this.l10n});

  final ActivityGrid grid;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardActivityCaption(activityWeeks),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: Gap.md),
        LayoutBuilder(
          builder: (context, constraints) {
            // The whole window is always on screen: a grid you have to
            // scroll to see the shape of has lost the only thing it was
            // better at than the numbers underneath. So the squares shrink
            // to fit instead, down to the smallest size still legible.
            const labels = 18.0;
            const gap = 2.0;
            final columns = grid.weeks.length;
            // Capped as well as floored: on a desktop window the squares
            // would grow until the grid read as a table of tiles rather
            // than as a shape. Past the cap it is centred instead, so the
            // card does not sit half empty.
            final side =
                ((constraints.maxWidth - labels - gap * columns) / columns)
                    .clamp(7.0, 22.0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: labels,
                  child: Column(
                    children: [
                      for (final day in grid.weeks.first)
                        SizedBox(
                          height: side + gap,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.weekdayLetter(day.day),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final week in grid.weeks)
                  Padding(
                    padding: const EdgeInsets.only(right: gap),
                    child: Column(
                      children: [
                        for (final day in week)
                          Padding(
                            padding: const EdgeInsets.only(bottom: gap),
                            child: _Cell(
                              day: day,
                              side: side,
                              // A square for a day that has not arrived is
                              // drawn away rather than empty: empty would
                              // claim the user skipped it.
                              future: day.day.isAfter(today),
                              l10n: l10n,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: Gap.md),
        if (grid.isEmpty)
          Text(l10n.dashboardActivityEmpty, style: theme.textTheme.bodySmall)
        else
          Text(
            [
              l10n.dashboardActivityTotal(grid.total),
              l10n.dashboardActivityDays(grid.activeDays),
              l10n.dashboardActivityRun(grid.longestRun(today)),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: Gap.sm),
        _Legend(l10n: l10n),
      ],
    );
  }
}

/// One day's square.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.side,
    required this.future,
    required this.l10n,
  });

  final ActivityDay day;
  final double side;
  final bool future;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(day.day);

    final square = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: future
            ? Colors.transparent
            : activityShade(Theme.of(context).colorScheme, day.level),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    // A day that has not happened yet has nothing to say about it, and a
    // tooltip on every one of them would put "nothing written down" under
    // the cursor for dates in the future.
    if (future) return square;

    return Tooltip(
      message: day.isEmpty
          ? l10n.dashboardActivityCellEmpty(date)
          : l10n.dashboardActivityCell(date, day.count),
      child: square,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(l10n.dashboardActivityLess, style: style),
        const SizedBox(width: Gap.xs),
        for (var level = 0; level <= 4; level++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activityShade(theme.colorScheme, level),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 2),
        Text(l10n.dashboardActivityMore, style: style),
      ],
    );
  }
}

/// The fill for a square at [level], 0 through 4.
///
/// One ramp of the app's own primary rather than GitHub's greens: the panel
/// already speaks in this colour, and a second palette here would read as a
/// widget borrowed from somewhere else. Level 0 is drawn in the surface tint
/// instead of left blank, so an untouched day is still a square and the grid
/// keeps its shape on a dark background as well as a light one.
Color activityShade(ColorScheme colors, int level) => switch (level) {
  0 => colors.surfaceContainerHighest,
  1 => colors.primary.withValues(alpha: 0.28),
  2 => colors.primary.withValues(alpha: 0.50),
  3 => colors.primary.withValues(alpha: 0.74),
  _ => colors.primary,
};
