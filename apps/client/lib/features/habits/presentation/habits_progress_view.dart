import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/habit_repository.dart';
import '../domain/habit_stats.dart';
import 'habit_providers.dart';

/// How the habits are going over the chosen window.
///
/// Renders as a plain column so the progress tab can scroll both this and the
/// streaks chart under a single range selector.
class HabitsProgressView extends ConsumerWidget {
  const HabitsProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(habitProgressRangeProvider);
    final stats = ref.watch(habitStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stats.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              '$error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (data) => _Body(stats: data, days: range.days),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats, required this.days});

  final HabitStats stats;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.statsCompleted,
                  value: '${stats.completions}',
                  caption: l10n.statsRangeCaption(days),
                  icon: Icons.check_circle_outline,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: StatTile(
                  label: l10n.statsSuccessRate,
                  value: l10n.statsPercent(stats.successRate),
                  caption: l10n.statsRangeCaption(days),
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(label: l10n.habitsCompletionsPerDay),
        if (stats.isEmpty)
          EmptyState(
            icon: Icons.show_chart,
            title: l10n.chartEmpty,
            hint: l10n.chartEmptyHint,
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.xl, Gap.lg, Gap.sm),
                child: SizedBox(
                  height: 220,
                  child: _CompletionsChart(perDay: stats.perDay),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Completions per day as a filled area.
///
/// The x axis is the position in the series rather than a timestamp, so days
/// stay evenly spaced regardless of the gaps between them.
class _CompletionsChart extends StatelessWidget {
  const _CompletionsChart({required this.perDay});

  final List<DailyCompletionCount> perDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final formatter = DateFormat('dd/MM');

    final maxCount = perDay
        .map((entry) => entry.count)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxCount + 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  value % 1 != 0 || value > maxCount
                  ? const SizedBox.shrink()
                  : Text(
                      '${value.toInt()}',
                      style: theme.textTheme.bodySmall,
                    ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              // Only the ends are labelled: a dense axis would be unreadable
              // over a year and adds nothing over a week.
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != perDay.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    formatter.format(perDay[index].day),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < perDay.length; i++)
                FlSpot(i.toDouble(), perDay[i].count.toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: accent,
            barWidth: 2,
            dotData: FlDotData(show: perDay.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
