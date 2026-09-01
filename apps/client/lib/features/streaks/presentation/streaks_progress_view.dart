import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/streak_repository.dart';
import 'streak_providers.dart';

/// How every streak has moved over the chosen window.
///
/// Renders as a plain column; the progress tab owns the scroll and the range.
class StreaksProgressView extends ConsumerWidget {
  const StreaksProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final series = ref.watch(streakSeriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.streaksEvolution),
        series.when(
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
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.show_chart,
                  title: l10n.chartEmpty,
                  hint: l10n.chartStreaksEmptyHint,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            height: 240,
                            child: _StreakChart(series: items),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    _Legend(series: items),
                  ],
                ),
        ),
      ],
    );
  }
}

/// One line per streak.
///
/// Every series carries the same window, one point per day, so the lines
/// already share an axis and a day nobody recorded reads as the zero it is.
class _StreakChart extends StatelessWidget {
  const _StreakChart({required this.series});

  final List<StreakSeries> series;

  static const _palette = [
    Color(0xFF3E5641),
    Color(0xFF8A9A5B),
    Color(0xFFB07D4A),
    Color(0xFF4F6D7A),
    Color(0xFF7D5A6B),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM');

    // Every series spans the whole window, so any of them gives the axis.
    final days = series.first.points.map((point) => point.day).toList();

    final maxCount = series
        .expand((line) => line.points)
        .map((point) => point.value)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxCount + 1,
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
              // The streak count is a whole number of repetitions; halves
              // would be meaningless.
              getTitlesWidget: (value, meta) =>
                  value % 1 != 0 || value > maxCount
                  ? const SizedBox.shrink()
                  : Text('${value.toInt()}', style: theme.textTheme.bodySmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != days.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    formatter.format(days[index]),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (var i = 0; i < series.length; i++)
            LineChartBarData(
              spots: [
                for (var day = 0; day < series[i].points.length; day++)
                  FlSpot(day.toDouble(), series[i].points[day].value),
              ],
              isCurved: false,
              color: _palette[i % _palette.length],
              barWidth: 2,
              dotData: FlDotData(show: days.length <= 14),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.series});

  final List<StreakSeries> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Wrap(
        spacing: Gap.lg,
        runSpacing: Gap.sm,
        children: [
          for (var i = 0; i < series.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        _StreakChart._palette[i % _StreakChart._palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Text(series[i].name, style: theme.textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}
