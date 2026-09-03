import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'meditation_providers.dart';

/// How the practice went over the chosen window.
class MeditationProgressView extends ConsumerWidget {
  const MeditationProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(meditationProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(meditationStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(meditationProgressRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.meditationAverageDaily,
            value: l10n.meditationMinutes(stats.averageMinutes),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.self_improvement_outlined,
            emphasize: true,
          ),
          StatTile(
            label: l10n.meditationDaysPractised,
            value: '${stats.daysPractised}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.event_available_outlined,
          ),
          StatTile(
            label: l10n.meditationLongestStreak,
            value: '${stats.longestStreak}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.local_fire_department_outlined,
          ),
        ],
        chartLabel: l10n.meditationMinutesPerDay,
        points: stats.isEmpty ? const [] : stats.perDay,
        emptyHint: l10n.meditationEmptyHint,
      ),
    );
  }
}
