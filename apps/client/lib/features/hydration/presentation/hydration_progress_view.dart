import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'hydration_providers.dart';

/// How the drinking went over the chosen window.
class HydrationProgressView extends ConsumerWidget {
  const HydrationProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(hydrationProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(hydrationStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(hydrationProgressRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.hydrationAverageDaily,
            value: l10n.hydrationMillilitres(stats.average),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.water_drop_outlined,
            emphasize: true,
          ),
          StatTile(
            label: l10n.hydrationDaysOnTarget,
            value: '${stats.daysOnTarget}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.event_available_outlined,
          ),
        ],
        chartLabel: l10n.hydrationPerDay,
        points: stats.isEmpty ? const [] : stats.perDay,
        // The daily target, so a day reads against what it was aiming at.
        chartReference: stats.goalMillilitres.toDouble(),
        emptyHint: l10n.hydrationEmptyHint,
      ),
    );
  }
}
