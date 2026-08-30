import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../streaks/presentation/streak_providers.dart';
import '../../streaks/presentation/streaks_progress_view.dart';
import 'habit_providers.dart';

/// The progress side of the Hábitos tab: habits and streaks under one window.
///
/// Both modules read their own range provider, but the user sees a single
/// control — two selectors on one screen would be noise, not choice.
class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(habitProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(habitStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) {
          ref.read(habitProgressRangeProvider.notifier).state = value;
          ref.read(streakProgressRangeProvider.notifier).state = value;
        },
        tiles: [
          StatTile(
            label: l10n.statsCompleted,
            value: '${stats.completions}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.check_circle_outline,
            emphasize: true,
          ),
          StatTile(
            label: l10n.statsSuccessRate,
            value: l10n.statsPercent(stats.successRate),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.trending_up,
          ),
        ],
        chartLabel: l10n.habitsCompletionsPerDay,
        points: [
          for (final entry in stats.perDay)
            (day: entry.day, value: entry.count.toDouble()),
        ],
        emptyHint: l10n.chartEmptyHint,
        extra: const StreaksProgressView(),
      ),
    );
  }
}
