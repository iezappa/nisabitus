import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/daily_area_chart.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../step_providers.dart';

/// How the walking went over the window the training report is showing.
///
/// Rendered as a plain column under the training figures rather than as its
/// own tab: walking is exercise, it answers to the same window, and a second
/// range picker on one screen would be noise rather than choice.
class StepsReport extends ConsumerWidget {
  const StepsReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(stepStatsProvider).valueOrNull;
    final range = ref.watch(stepReportRangeProvider);

    if (stats == null) return const SizedBox.shrink();

    if (stats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(label: l10n.steps),
          EmptyState(
            icon: Icons.directions_walk,
            title: l10n.chartEmpty,
            hint: l10n.stepsEmptyHint,
          ),
        ],
      );
    }

    final goal = ref.watch(stepGoalProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.steps),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.stepsAverage,
                  value: _grouped(stats.average.round()),
                  // Said out loud, because the figure is not what most people
                  // would assume: a day nobody wrote down is not a day of no
                  // walking, so it is left out rather than averaged in as
                  // zero.
                  caption: l10n.stepsAveragedOverLogged(range.days),
                  icon: Icons.directions_walk,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: StatTile(
                  label: l10n.stepsGoalDays,
                  value: '${stats.goalDays}/${stats.days}',
                  caption: l10n.statsPercent(stats.goalPercent),
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.stepsBest,
                  value: _grouped(stats.best?.steps ?? 0),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: StatTile(
                  label: l10n.stepsDaysLogged,
                  value: '${stats.days}',
                  icon: Icons.event_available_outlined,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(label: l10n.stepsPerDay),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.sm,
                Gap.xl,
                Gap.lg,
                Gap.sm,
              ),
              child: SizedBox(
                height: 210,
                child: DailyAreaChart(
                  points: stats.perDay,
                  // The target as a line across the chart, so a day is read
                  // against it rather than against the tallest bar.
                  reference: goal?.steps.toDouble(),
                ),
              ),
            ),
          ),
        ),
        if (goal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
            child: Text(
              '${l10n.stepsGoal}: ${_grouped(goal.steps)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Thousands separated the way they are written in Spanish.
String _grouped(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return buffer.toString();
}
