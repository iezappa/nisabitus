import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/sleep_stats.dart';

/// Whether the insights card is open, remembered between launches.
final sleepInsightsExpandedProvider =
    StateNotifierProvider<BoolPreference, bool>(
      (ref) => BoolPreference(
        ref.watch(sharedPreferencesProvider),
        'sleep.insights.expanded',
        fallback: true,
      ),
    );

/// A short, plain reading of the window: how much and how evenly.
///
/// The tone stays positive or neutral — this is a wellbeing app, not a
/// scoreboard.
class SleepInsightsCard extends ConsumerWidget {
  const SleepInsightsCard({required this.stats, super.key});

  final SleepStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final expanded = ref.watch(sleepInsightsExpandedProvider);

    final averageMessage = switch (stats.average) {
      < 7 => l10n.sleepInsightAverageLow,
      > 9 => l10n.sleepInsightAverageHigh,
      _ => l10n.sleepInsightAverageGood,
    };
    // Under an hour of spread reads as a steady pattern.
    final steady = stats.consistency < 1;

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                ref.read(sleepInsightsExpandedProvider.notifier).toggle(),
            child: Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.spa_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      l10n.sleepInsights.toUpperCase(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Insight(
                    icon: Icons.nightlight_outlined,
                    text: averageMessage,
                  ),
                  const SizedBox(height: Gap.md),
                  _Insight(
                    icon: steady ? Icons.timeline : Icons.ssid_chart,
                    text: steady
                        ? l10n.sleepInsightConsistencySteady
                        : l10n.sleepInsightConsistencyErratic,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Gap.md),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
