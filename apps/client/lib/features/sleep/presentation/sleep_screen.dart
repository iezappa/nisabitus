import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/range_selector.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/week_date_selector.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/sleep_log.dart';
import '../domain/sleep_stats.dart';
import 'sleep_labels.dart';
import 'sleep_providers.dart';
import 'widgets/sleep_chart.dart';
import 'widgets/sleep_insights_card.dart';
import 'widgets/sleep_log_form.dart';

/// The Sueño tab: pick a day, record the night, then look at the trend.
class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedDayProvider);
    final today = ref.watch(todayProvider);
    final night = ref.watch(sleepForSelectedDayProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(l10n.sleepTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          WeekDateSelector(
            selected: selected,
            today: today,
            onSelected: (day) =>
                ref.read(selectedDayProvider.notifier).state = day,
          ),
          night.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Gap.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Text(
                '$error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            data: (log) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(label: l10n.sleepLastNight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  child: _NightCard(log: log),
                ),
                const SizedBox(height: Gap.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  child: SleepLogForm(
                    existingHours: log?.hours,
                    onSave: (hours) =>
                        ref.read(sleepActionsProvider).save(hours),
                  ),
                ),
              ],
            ),
          ),
          const _History(),
        ],
      ),
    );
  }
}

/// The night the strip is pointing at, with its derived quality.
class _NightCard extends StatelessWidget {
  const _NightCard({required this.log});

  final SleepLog? log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final night = log;

    if (night == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Gap.sm),
          child: _NoRecord(),
        ),
      );
    }

    final color = qualityColor(context, night.quality);

    return Card(
      // Named so tests can tell this figure apart from the average tile,
      // which renders the same string.
      key: const ValueKey('sleep.night-card'),
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.sleepHours(formatHours(night.hours)),
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    l10n.qualityName(night.quality),
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecord extends StatelessWidget {
  const _NoRecord();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return EmptyState(
      icon: Icons.bedtime_outlined,
      title: l10n.sleepNoRecord,
      hint: l10n.sleepNoRecordHint,
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(sleepHistoryRangeProvider);
    final stats = ref.watch(sleepStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.sleepHistory),
        RangeSelector(
          value: range,
          onChanged: (value) =>
              ref.read(sleepHistoryRangeProvider.notifier).state = value,
        ),
        stats.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              '$error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (data) => data.isEmpty
              ? EmptyState(
                  icon: Icons.show_chart,
                  title: l10n.chartEmpty,
                  hint: l10n.sleepNoRecordHint,
                )
              : _HistoryBody(stats: data),
        ),
      ],
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.stats});

  final SleepStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.xl, Gap.lg, Gap.sm),
              child: SizedBox(height: 200, child: SleepChart(logs: stats.logs)),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: l10n.sleepAverage,
                      value: l10n.sleepHours(
                        stats.average.toStringAsFixed(1),
                      ),
                      icon: Icons.nightlight_outlined,
                      emphasize: true,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: StatTile(
                      label: l10n.sleepRecords,
                      value: '${stats.count}',
                      icon: Icons.event_available_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: l10n.sleepOptimalNights,
                      value: l10n.statsPercent(stats.optimalPercent),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: StatTile(
                      label: l10n.sleepRange,
                      value: l10n.sleepRangeValue(
                        formatHours(stats.minHours ?? 0),
                        formatHours(stats.maxHours ?? 0),
                      ),
                      icon: Icons.straighten,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              SleepInsightsCard(stats: stats),
            ],
          ),
        ),
      ],
    );
  }
}
