import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/range_selector.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pomodoro_repository.dart';
import '../domain/pomodoro_session.dart';
import '../domain/pomodoro_stats.dart';
import 'pomodoro_providers.dart';
import 'widgets/focus_ring.dart';
import 'widgets/pomodoro_form_dialog.dart';

/// The Pomodoro tab: the session list, or the focus mode for one of them.
class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedSessionProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(l10n.pomodoroTitle),
      ),
      floatingActionButton: selected != null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final draft = await showPomodoroForm(context);
                if (draft != null) {
                  await ref.read(pomodoroActionsProvider).create(draft);
                }
              },
              tooltip: l10n.pomodoroNew,
              child: const Icon(Icons.add),
            ),
      body: selected == null
          ? const _SessionList()
          : _FocusMode(session: selected),
    );
  }
}

/// The running session: the ring, the controls, and the ways out.
class _FocusMode extends ConsumerWidget {
  const _FocusMode({required this.session});

  final PomodoroSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timer = ref.watch(focusTimerProvider(session));
    final controller = ref.read(focusTimerProvider(session).notifier);
    final actions = ref.read(pomodoroActionsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        SectionHeader(label: l10n.pomodoroCurrentSession),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Text(
              session.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: Gap.xl),
        Center(
          child: FocusRing(
            state: timer,
            label: l10n.pomodoroCycleOf(
              session.completedCycles,
              session.cycles,
            ),
          ),
        ),
        const SizedBox(height: Gap.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              iconSize: 28,
              onPressed: controller.pause,
              icon: const Icon(Icons.pause),
              tooltip: l10n.pomodoroPause,
            ),
            const SizedBox(width: Gap.lg),
            IconButton.filled(
              iconSize: 36,
              onPressed: timer.running ? controller.pause : controller.start,
              icon: Icon(timer.running ? Icons.pause : Icons.play_arrow),
              tooltip: timer.running ? l10n.pomodoroPause : l10n.pomodoroStart,
            ),
            const SizedBox(width: Gap.lg),
            IconButton.filledTonal(
              iconSize: 28,
              onPressed: controller.skipPhase,
              icon: const Icon(Icons.skip_next),
              tooltip: l10n.pomodoroSkip,
            ),
          ],
        ),
        const SizedBox(height: Gap.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Column(
            children: [
              FilledButton.icon(
                onPressed: () => actions.finish(session.id),
                icon: const Icon(Icons.check),
                label: Text(l10n.pomodoroFinish),
              ),
              const SizedBox(height: Gap.sm),
              TextButton(
                onPressed: () => actions.cancel(session.id),
                child: Text(l10n.pomodoroCancel),
              ),
              TextButton(
                // Leaves the session exactly as it is; only the selection
                // goes away.
                onPressed: () =>
                    ref.read(selectedSessionIdProvider.notifier).state = null,
                child: Text(l10n.pomodoroClose),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionList extends ConsumerWidget {
  const _SessionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(pomodoroListProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        SectionHeader(label: l10n.pomodoroSessions),
        page.when(
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
          data: (data) => data.total == 0
              ? EmptyState(
                  icon: Icons.timer_outlined,
                  title: l10n.pomodoroEmpty,
                  hint: l10n.pomodoroEmptyHint,
                )
              : _Sessions(page: data),
        ),
        const _Stats(),
      ],
    );
  }
}

class _Sessions extends ConsumerWidget {
  const _Sessions({required this.page});

  final PomodoroPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in page.sessions)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: Card(
              child: ListTile(
                title: Text(session.name),
                subtitle: Text(
                  [
                    if (session.category case final c? when c.isNotEmpty) c,
                    l10n.pomodoroCycleOf(session.completedCycles, session.cycles),
                    l10n.pomodoroMinutes(session.focusDuration),
                  ].join(' · '),
                ),
                trailing: _ProgressBadge(progress: session.progress),
                onTap: () => ref
                    .read(selectedSessionIdProvider.notifier)
                    .state = session.id,
                onLongPress: () => _showActions(context, ref, session),
              ),
            ),
          ),
        if (page.pageCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: page.page == 0
                    ? null
                    : () => ref
                          .read(pomodoroPageProvider.notifier)
                          .update((v) => v - 1),
              ),
              Text(
                l10n.journalPage(page.page + 1, page.pageCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: page.page >= page.pageCount - 1
                    ? null
                    : () => ref
                          .read(pomodoroPageProvider.notifier)
                          .update((v) => v + 1),
              ),
            ],
          ),
      ],
    );
  }
}

/// Edit and delete, kept off the row so tapping it means one thing: run it.
Future<void> _showActions(
  BuildContext context,
  WidgetRef ref,
  PomodoroSession session,
) async {
  final l10n = AppLocalizations.of(context);
  final actions = ref.read(pomodoroActionsProvider);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.actionEdit),
            onTap: () async {
              Navigator.of(sheet).pop();
              final draft = await showPomodoroForm(
                context,
                existing: session,
              );
              if (draft != null) await actions.update(session.id, draft);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(sheet).colorScheme.error,
            ),
            title: Text(l10n.actionDelete),
            onTap: () async {
              Navigator.of(sheet).pop();
              if (await confirmDelete(context, session.name)) {
                await actions.delete(session.id);
              }
            },
          ),
        ],
      ),
    ),
  );
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.progress});

  final SessionProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final (label, colour) = switch (progress) {
      SessionProgress.cancelled => (
        l10n.pomodoroStateCancelled,
        theme.colorScheme.error,
      ),
      SessionProgress.completed => (
        l10n.pomodoroStateCompleted,
        theme.colorScheme.primary,
      ),
      SessionProgress.inProgress => (
        l10n.pomodoroStateInProgress,
        theme.colorScheme.onSurfaceVariant,
      ),
      SessionProgress.pending => (
        l10n.pomodoroStatePending,
        theme.colorScheme.outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: colour),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: colour),
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(pomodoroStatsRangeProvider);
    final stats = ref.watch(pomodoroStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.pomodoroStats),
        RangeSelector(
          value: range,
          onChanged: (value) =>
              ref.read(pomodoroStatsRangeProvider.notifier).state = value,
        ),
        stats.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => const SizedBox.shrink(),
          data: (data) => data.isEmpty
              ? EmptyState(
                  icon: Icons.show_chart,
                  title: l10n.chartEmpty,
                  hint: l10n.pomodoroEmptyHint,
                )
              : _StatsBody(stats: data),
        ),
      ],
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final PomodoroStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hours = stats.focusMinutes ~/ 60;
    final minutes = stats.focusMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.pomodoroTotalFocus,
                  value: hours == 0
                      ? l10n.pomodoroMinutes(minutes)
                      : l10n.pomodoroHoursMinutes(hours, minutes),
                  icon: Icons.timer_outlined,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: StatTile(
                  label: l10n.pomodoroTotalCycles,
                  value: '${stats.cycles}',
                  icon: Icons.repeat,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(label: l10n.pomodoroMinutesPerDay),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.xl, Gap.lg, Gap.sm),
              child: SizedBox(
                height: 200,
                child: _MinutesChart(perDay: stats.perDay),
              ),
            ),
          ),
        ),
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
    );
  }
}

class _MinutesChart extends StatelessWidget {
  const _MinutesChart({required this.perDay});

  final List<DailyFocusMinutes> perDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final formatter = DateFormat('dd/MM');
    final peak = perDay
        .map((e) => e.minutes)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (peak * 1.2).ceilToDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) =>
                  Text('${value.toInt()}', style: theme.textTheme.bodySmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != perDay.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    formatter.format(perDay[index].day),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < perDay.length; i++)
                FlSpot(i.toDouble(), perDay[i].minutes.toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: accent,
            barWidth: 2,
            dotData: FlDotData(show: perDay.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
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
