import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'sleep_labels.dart';
import 'sleep_providers.dart';
import 'widgets/sleep_insights_card.dart';

/// How the nights went over the chosen window.
class SleepProgressView extends ConsumerWidget {
  const SleepProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(sleepHistoryRangeProvider);

    return AsyncSection(
      value: ref.watch(sleepStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(sleepHistoryRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.sleepAverage,
            value: l10n.sleepHours(stats.average.toStringAsFixed(1)),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.nightlight_outlined,
            emphasize: true,
          ),
          StatTile(
            label: l10n.sleepRecords,
            value: '${stats.count}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.event_available_outlined,
          ),
          StatTile(
            label: l10n.sleepOptimalNights,
            value: l10n.statsPercent(stats.optimalPercent),
            icon: Icons.check_circle_outline,
          ),
          StatTile(
            label: l10n.sleepRange,
            value: l10n.sleepRangeValue(
              formatHours(stats.minHours ?? 0),
              formatHours(stats.maxHours ?? 0),
            ),
            icon: Icons.straighten,
          ),
        ],
        chartLabel: l10n.sleepHoursPerNight,
        points: stats.isEmpty ? const [] : stats.perDay,
        // Pinned so two windows are read against the same scale, and stopped
        // at twelve because a night off the top of that is not a night.
        chartMaxY: 12,
        chartInterval: 3,
        emptyHint: l10n.sleepNoRecordHint,
        extra: stats.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
                child: SleepInsightsCard(stats: stats),
              ),
      ),
    );
  }
}
