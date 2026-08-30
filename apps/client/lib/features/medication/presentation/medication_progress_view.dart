import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'medication_providers.dart';

/// How the regimen was kept over the chosen window.
///
/// Adherence is measured against what is active today, so a window longer
/// than the current regimen reads a change of prescription as missed days.
class MedicationProgressView extends ConsumerWidget {
  const MedicationProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(medicationProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(medicationStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(medicationProgressRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.medsAdherence,
            value: l10n.statsPercent(stats.adherencePercent),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.check_circle_outline,
            emphasize: true,
          ),
          StatTile(
            label: l10n.medsDaysComplete,
            value: '${stats.completeDays}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.event_available_outlined,
          ),
        ],
        chartLabel: l10n.medsAdherencePerDay,
        points: stats.isEmpty ? const [] : stats.perDay,
        // Pinned to a full day so two windows stay comparable, and stepped in
        // quarters so the line reads as a share rather than a count.
        chartMaxY: 100,
        chartInterval: 25,
        emptyHint: l10n.medsEmptyHint,
      ),
    );
  }
}
