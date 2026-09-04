import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'exercise_providers.dart';

/// How the training went over the chosen window.
class ExerciseProgressView extends ConsumerWidget {
  const ExerciseProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(exerciseProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(exerciseStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(exerciseProgressRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.exerciseVolume,
            value: l10n.exerciseVolumeValue(_round(stats.volume)),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.fitness_center,
            emphasize: true,
          ),
          StatTile(
            label: l10n.exerciseDaysTrained,
            value: '${stats.daysTrained}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.event_available_outlined,
          ),
          StatTile(
            label: l10n.exerciseTotalSets,
            value: '${stats.sets}',
            icon: Icons.repeat,
          ),
          StatTile(
            label: l10n.exerciseTotalReps,
            value: '${stats.reps}',
            icon: Icons.numbers,
          ),
        ],
        chartLabel: l10n.exerciseVolumePerDay,
        points: stats.isEmpty ? const [] : stats.perDay,
        emptyHint: l10n.planEmptyHint,
      ),
    );
  }

  /// Kilos read as whole numbers unless the plates were fractional.
  static String _round(double value) =>
      value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1);
}
