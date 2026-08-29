import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// One value attached to one day.
typedef DailyPoint = ({DateTime day, double value});

/// The one area chart every progress view uses.
///
/// Extracted after the third near-identical copy: habits, sleep and pomodoro
/// had drifted into three slightly different axes for the same picture.
class DailyAreaChart extends StatelessWidget {
  const DailyAreaChart({
    required this.points,
    this.minY = 0,
    this.maxY,
    this.yInterval,
    this.wholeNumbersOnly = true,
    this.reference,
    super.key,
  });

  final List<DailyPoint> points;

  final double minY;

  /// Pinned when two windows must stay comparable; otherwise it follows the
  /// data with a little headroom.
  final double? maxY;

  final double? yInterval;

  /// Hides half-step labels for counts, which cannot be fractional.
  final bool wholeNumbersOnly;

  /// A dashed line to read the values against, such as a target.
  final double? reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final formatter = DateFormat('dd/MM');

    final peak = points
        .map((p) => p.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY ?? (peak <= 0 ? 1 : peak * 1.2);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: top,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: reference == null
            ? const ExtraLinesData()
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: reference!,
                    color: accent.withValues(alpha: 0.35),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ],
              ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (wholeNumbersOnly && value % 1 != 0) {
                  return const SizedBox.shrink();
                }
                if (value > peak && maxY == null) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              // Only the ends are labelled: a dense axis is unreadable over
              // a year and adds nothing over a week.
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    formatter.format(points[index].day),
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
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: accent,
            barWidth: 2,
            dotData: FlDotData(show: points.length <= 14),
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
