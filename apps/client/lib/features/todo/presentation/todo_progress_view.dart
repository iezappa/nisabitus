import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/progress_layout.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import 'todo_providers.dart';

/// What the board finished over the chosen window, and where it stands now.
///
/// Only the completions belong to the window: open and overdue describe the
/// board as it is today, whichever window is picked.
class TodoProgressView extends ConsumerWidget {
  const TodoProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(todoProgressRangeProvider);

    return AsyncSection(
      value: ref.watch(todoStatsProvider),
      builder: (stats) => ProgressLayout(
        range: range,
        onRangeChanged: (value) =>
            ref.read(todoProgressRangeProvider.notifier).state = value,
        tiles: [
          StatTile(
            label: l10n.todoCompleted,
            value: '${stats.completed}',
            caption: l10n.statsRangeCaption(range.days),
            icon: Icons.check_circle_outline,
            emphasize: true,
          ),
          StatTile(
            label: l10n.todoOpen,
            value: '${stats.open}',
            icon: Icons.radio_button_unchecked,
          ),
          StatTile(
            label: l10n.todoOverdue,
            value: '${stats.overdue}',
            icon: Icons.schedule,
          ),
        ],
        chartLabel: l10n.todoCompletedPerDay,
        points: stats.completed == 0 ? const [] : stats.perDay,
        emptyHint: l10n.todoProgressEmptyHint,
      ),
    );
  }
}
