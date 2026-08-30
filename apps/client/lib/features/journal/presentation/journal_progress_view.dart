import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'journal_providers.dart';
import 'journal_screen.dart';

/// How much was written over the chosen window.
///
/// There is one entry per day at most, so the interesting figures are not
/// how many entries there are but how much of the window they cover and how
/// long the writing held.
class JournalProgressView extends ConsumerWidget {
  const JournalProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(journalProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(journalStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) {
          ref.read(journalProgressRangeProvider.notifier).state = value;
          // A narrower window can have fewer pages than the one being read.
          ref.read(journalHistoryPageProvider.notifier).state = 0;
        },
        tiles: [
          StatTile(
            label: l10n.journalEntriesWritten,
            value: '${stats.entries}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.edit_note,
            emphasize: true,
          ),
          StatTile(
            label: l10n.journalCoverage,
            value: l10n.statsPercent(stats.coveragePercent),
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.calendar_month_outlined,
          ),
          StatTile(
            label: l10n.journalLongestRun,
            value: l10n.progressDays(stats.longestRun),
            icon: Icons.local_fire_department_outlined,
          ),
        ],
        chartLabel: l10n.journalPerDay,
        points: stats.isEmpty ? const [] : stats.perDay,
        // A day is written or it is not, so the axis stops at one.
        chartMaxY: 1,
        chartInterval: 1,
        emptyHint: l10n.journalHistoryEmptyHint,
        extra: const JournalHistory(),
      ),
    );
  }
}
