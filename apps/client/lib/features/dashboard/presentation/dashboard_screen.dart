import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_tab.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/centered_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../journal/domain/journal_content.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../sleep/presentation/sleep_labels.dart';
import '../../todo/domain/task.dart';
import '../../todo/presentation/todo_labels.dart';
import 'dashboard_providers.dart';

/// The Panel tab: what today looks like across every module.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(dashboardProvider);
    final name = ref.watch(profileNameProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(l10n.tabDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.dashboardRefresh,
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
          const SizedBox(width: Gap.xs),
        ],
      ),
      body: CenteredContent(
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              '$error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.only(bottom: Gap.xxl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty
                          ? l10n.dashboardGreetingAnonymous
                          : l10n.dashboardGreeting(name),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      l10n.dashboardSubtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
                // The two tiles are a pair, so they are one height: only
                // one of them carries a caption, and sized to their own
                // content they end up centred against each other, which
                // reads as a mistake rather than as a pair.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go(AppTab.todo.path),
                          child: StatTile(
                            label: l10n.dashboardPendingTasks,
                            value: '${data.openTasks}',
                            caption: data.overdueTasks == 0
                                ? l10n.dashboardNoOverdue
                                : l10n.dashboardOverdue(data.overdueTasks),
                            icon: Icons.task_alt_outlined,
                            emphasize: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go(AppTab.habits.path),
                          child: StatTile(
                            label: l10n.dashboardHabitsToday,
                            value: l10n.dashboardHabitsRatio(
                              data.habitsDone,
                              data.habitsTotal,
                            ),
                            icon: Icons.checklist_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _QuickActions(),
              SectionHeader(label: l10n.dashboardFocus),
              _Focus(tasks: data.focus),
              SectionHeader(label: l10n.dashboardHealth),
              _Health(summary: data),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shortcuts to the other tabs, so the panel is a way in and not only a
/// summary.
///
/// Built from the tabs the user actually kept: offering a way into a screen
/// they hid would put it back in front of them through the side door.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      for (final tab in ref.watch(visibleTabsProvider))
        // The panel is where the user already is.
        if (tab != AppTab.dashboard) tab,
    ];

    if (tabs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.dashboardQuickActions),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final tab in tabs)
                ActionChip(
                  avatar: Icon(tab.icon, size: 18),
                  label: Text(tab.label(l10n)),
                  onPressed: () => context.go(tab.path),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Focus extends ConsumerWidget {
  const _Focus({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);

    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.self_improvement,
        title: l10n.dashboardFocusEmpty,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Card(
        child: Column(
          children: [
            for (final task in tasks)
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.circle_outlined,
                  size: 16,
                  color: priorityColor(context, task.priority),
                ),
                title: Text(task.title, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    ?task.projectName,
                    l10n.dueName(task.dueState(today)) ?? l10n.dashboardNoDue,
                    if (task.dueDate case final d?)
                      DateFormat('dd/MM').format(d),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => context.go(AppTab.todo.path),
              ),
          ],
        ),
      ),
    );
  }
}

class _Health extends StatelessWidget {
  const _Health({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sleep = summary.sleep;
    final journal = summary.journal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(l10n.dashboardSleepToday),
              trailing: Text(
                sleep == null ? '—' : l10n.sleepHours(formatHours(sleep.hours)),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () => context.go(AppTab.health.path),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.journalTitle),
              subtitle: Text(
                journal == null
                    ? l10n.dashboardNoJournal
                    // The panel flattens the whole entry into one line,
                    // unlike the journal, which picks a single section.
                    : JournalContent.dashboardPreview(
                        journal.content.serialize(),
                      ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                summary.journalReady
                    ? l10n.dashboardJournalReady
                    : l10n.dashboardJournalPending,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: summary.journalReady
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => context.go(AppTab.journal.path),
            ),
          ],
        ),
      ),
    );
  }
}
