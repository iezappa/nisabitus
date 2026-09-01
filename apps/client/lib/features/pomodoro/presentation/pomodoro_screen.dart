import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pomodoro_repository.dart';
import '../domain/pomodoro_session.dart';
import 'pomodoro_progress_view.dart';
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

    // Focus mode is a mode, not a view: while a session runs there is nothing
    // to switch to, so it gets a bare frame instead of the module one.
    if (selected != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const SettingsButton(),
          title: Text(l10n.pomodoroTitle),
        ),
        body: _FocusMode(session: selected),
      );
    }

    return ModuleScaffold(
      title: l10n.pomodoroTitle,
      list: const _SessionList(),
      progress: const PomodoroProgressView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final draft = await showPomodoroForm(context);
          if (draft != null) {
            await ref.read(pomodoroActionsProvider).create(draft);
          }
        },
        tooltip: l10n.pomodoroNew,
        child: const Icon(Icons.add),
      ),
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
        AsyncSection(
          value: page,
          builder: (data) => data.total == 0
              ? EmptyState(
                  icon: Icons.timer_outlined,
                  title: l10n.pomodoroEmpty,
                  hint: l10n.pomodoroEmptyHint,
                )
              : _Sessions(page: data),
        ),
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
                    l10n.pomodoroCycleOf(
                      session.completedCycles,
                      session.cycles,
                    ),
                    l10n.pomodoroMinutes(session.focusDuration),
                  ].join(' · '),
                ),
                trailing: _ProgressBadge(progress: session.progress),
                onTap: () =>
                    ref.read(selectedSessionIdProvider.notifier).state =
                        session.id,
                onLongPress: () async {
                  final actions = ref.read(pomodoroActionsProvider);
                  final draft = await showPomodoroForm(
                    context,
                    existing: session,
                    onDelete: () => actions.delete(session.id),
                  );
                  if (draft != null) await actions.update(session.id, draft);
                },
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
