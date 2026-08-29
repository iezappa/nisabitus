import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/sleep_log.dart';

/// Hours per night over the chosen window.
///
/// The y axis is pinned to 0–12 as the spec asks: a fixed scale makes two
/// windows comparable at a glance, which a self-scaling axis would not.
class SleepChart extends StatelessWidget {
  const SleepChart({required this.logs, super.key});

  final List<SleepLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final formatter = DateFormat('dd/MM');

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 12,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 3,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // The eight hour mark, so a night reads against a target rather
            // than against nothing.
            HorizontalLine(
              y: 8,
              color: accent.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 3,
              getTitlesWidget: (value, meta) =>
                  Text('${value.toInt()}', style: theme.textTheme.bodySmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != logs.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    formatter.format(logs[index].date),
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
              for (var i = 0; i < logs.length; i++)
                FlSpot(i.toDouble(), logs[i].hours),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: accent,
            barWidth: 2,
            dotData: FlDotData(show: logs.length <= 14),
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
