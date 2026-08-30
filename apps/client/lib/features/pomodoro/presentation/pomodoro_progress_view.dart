import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pomodoro_stats.dart';
import 'pomodoro_providers.dart';

/// How much focus was served over the chosen window.
class PomodoroProgressView extends ConsumerWidget {
  const PomodoroProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(pomodoroStatsRangeProvider);

    return AsyncSection(
      value: ref.watch(pomodoroStatsProvider),
      builder: (stats) {
        final hours = stats.focusMinutes ~/ 60;
        final minutes = stats.focusMinutes % 60;

        return ProgressLayout(
          range: range,
          onRangeChanged: (value) =>
              ref.read(pomodoroStatsRangeProvider.notifier).state = value,
          tiles: [
            StatTile(
              label: l10n.pomodoroTotalFocus,
              value: hours == 0
                  ? l10n.pomodoroMinutes(minutes)
                  : l10n.pomodoroHoursMinutes(hours, minutes),
              caption: l10n.statsRangeCaption(range.days),
              icon: Icons.timer_outlined,
              emphasize: true,
            ),
            StatTile(
              label: l10n.pomodoroTotalCycles,
              value: '${stats.cycles}',
              caption: l10n.statsRangeCaption(range.days),
              icon: Icons.repeat,
            ),
          ],
          chartLabel: l10n.pomodoroMinutesPerDay,
          points: [
            for (final entry in stats.perDay)
              (day: entry.day, value: entry.minutes.toDouble()),
          ],
          emptyHint: l10n.pomodoroEmptyHint,
          extra: stats.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(label: l10n.pomodoroByCategory),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Gap.lg),
                          child: _CategoryBreakdown(stats: stats),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Focus minutes per category, as proportional bars.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.stats});

  final PomodoroStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final entries = stats.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = entries.first.value;

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      l10n.pomodoroMinutes(entry.value),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: entry.value / peak,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
