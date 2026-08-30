import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../time/progress_range.dart';
import 'daily_area_chart.dart';
import 'empty_state.dart';
import 'range_selector.dart';
import 'section_header.dart';
import 'stat_tile.dart';
import '../../l10n/app_localizations.dart';

/// The shape every progress view shares: a window picker, a row of figures,
/// and a chart of the same window.
///
/// Written once so no module invents its own arrangement of the same three
/// things.
class ProgressLayout extends ConsumerWidget {
  const ProgressLayout({
    required this.range,
    required this.onRangeChanged,
    required this.tiles,
    required this.chartLabel,
    required this.points,
    this.chartMaxY,
    this.chartInterval,
    this.chartReference,
    this.emptyHint,
    this.extra,
    super.key,
  });

  final ProgressRange range;
  final ValueChanged<ProgressRange> onRangeChanged;

  /// The figures, laid out two to a row.
  final List<StatTile> tiles;

  final String chartLabel;
  final List<DailyPoint> points;

  final double? chartMaxY;
  final double? chartInterval;
  final double? chartReference;

  /// Shown in place of the chart when the window holds nothing.
  final String? emptyHint;

  /// Anything the module wants under the chart.
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: Gap.lg, bottom: 96),
      children: [
        RangeSelector(value: range, onChanged: onRangeChanged),
        // Two to a row: three or four figures crammed side by side turn the
        // number, which is what the user came to read, into the smallest
        // thing on screen. An odd last one takes the whole width.
        for (var row = 0; row * 2 < tiles.length; row++)
          Padding(
            padding: EdgeInsets.fromLTRB(
              Gap.lg,
              row == 0 ? Gap.lg : Gap.md,
              Gap.lg,
              0,
            ),
            child: Row(
              children: [
                for (
                  var i = row * 2;
                  i < tiles.length && i < row * 2 + 2;
                  i++
                ) ...[
                  if (i > row * 2) const SizedBox(width: Gap.md),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          ),
        SectionHeader(label: chartLabel),
        if (points.isEmpty)
          EmptyState(
            icon: Icons.show_chart,
            title: l10n.chartEmpty,
            hint: emptyHint,
          )
        else
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
                    points: points,
                    maxY: chartMaxY,
                    yInterval: chartInterval,
                    reference: chartReference,
                  ),
                ),
              ),
            ),
          ),
        ?extra,
      ],
    );
  }
}
