import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'nutrition_providers.dart';

/// How the eating went over the chosen window.
class NutritionProgressView extends ConsumerWidget {
  const NutritionProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(nutritionProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(nutritionStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(nutritionProgressRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.nutritionAverageDaily,
            value: l10n.nutritionKcal(stats.averageCalories),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.local_fire_department_outlined,
            emphasize: true,
          ),
          StatTile(
            label: l10n.nutritionDaysLogged,
            value: '${stats.daysLogged}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.event_available_outlined,
          ),
        ],
        chartLabel: l10n.nutritionCaloriesPerDay,
        points: stats.isEmpty ? const [] : stats.perDay,
        // The daily target, so a day reads against what it was aiming at.
        chartReference: stats.goalCalories.toDouble(),
        emptyHint: l10n.nutritionEmptyHint,
      ),
    );
  }
}
