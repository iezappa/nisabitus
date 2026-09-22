import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/save_failure.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/focus_sound.dart';
import '../domain/pomodoro_repository.dart';
import '../domain/pomodoro_session.dart';
import 'pomodoro_progress_view.dart';
import 'pomodoro_providers.dart';
import 'widgets/focus_ring.dart';
import 'widgets/focus_sound_dialog.dart';
import 'widgets/focus_sound_player.dart';
import 'widgets/pomodoro_form_dialog.dart';

/// The Pomodoro tab: the clock on one side, what has been run on the other.
///
/// Two panes rather than two screens. Focus mode used to replace the whole
/// tab, so starting a session hid the list it came from and the only way
/// back was a button that said "close"; and with nothing running there was
/// no clock at all, which is an odd thing for a timer to be missing. Now the
/// clock is always there — locked and grey until a session is picked, in the
/// accent once one is — and the history sits beside it.
class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  /// Below this the two panes stop being two panes.
  ///
  /// Each needs about a phone's width to be worth anything, so under twice
  /// that they stack: the clock first, the history under it.
  static const twoPaneWidth = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ModuleScaffold(
      title: l10n.pomodoroTitle,
      // Panes, not a column of cards: the reading measure would squeeze
      // both of them into half the window.
      listMaxWidth: double.infinity,
      list: const _Desk(),
      progress: const PomodoroProgressView(),
    );
  }
}

class _Desk extends StatelessWidget {
  const _Desk();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < PomodoroScreen.twoPaneWidth) {
          return const SingleChildScrollView(
            padding: EdgeInsets.only(bottom: Gap.xxl),
            child: Column(children: [_ClockPane(), _HistoryPane()]),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: Gap.xxl),
                child: _ClockPane(),
              ),
            ),
            VerticalDivider(width: 1),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: Gap.xxl),
                child: _HistoryPane(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The left pane: the clock, its controls, and what is playing.
class _ClockPane extends ConsumerWidget {
  const _ClockPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(selectedSessionProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: session == null
                  ? const _IdleClock()
                  : _RunningClock(session: session),
            ),
          ),
          const SizedBox(height: Gap.lg),
          SectionHeader(label: l10n.pomodoroSound),
          const _SoundBar(),
          const _Player(),
        ],
      ),
    );
  }
}

/// The clock with nothing behind it.
class _IdleClock extends StatelessWidget {
  const _IdleClock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Text(l10n.pomodoroIdle, style: theme.textTheme.titleMedium),
        const SizedBox(height: Gap.lg),
        FocusRing.idle(label: l10n.pomodoroIdleHint),
        const SizedBox(height: Gap.lg),
        // The same three controls, in the same places, all of them off. A
        // pane that loses its buttons when idle moves everything else up
        // and back down again every time a session is picked.
        const _Controls(),
      ],
    );
  }
}

/// The clock with a session behind it.
class _RunningClock extends ConsumerWidget {
  const _RunningClock({required this.session});

  final PomodoroSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final timer = ref.watch(focusTimerProvider(session));
    final controller = ref.read(focusTimerProvider(session).notifier);
    final actions = ref.read(pomodoroActionsProvider);

    return Column(
      children: [
        Text(
          session.name,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (session.category case final category? when category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(category, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: Gap.lg),
        FocusRing(
          state: timer,
          label: l10n.pomodoroCycleOf(session.completedCycles, session.cycles),
        ),
        const SizedBox(height: Gap.lg),
        _Controls(
          running: timer.running,
          onPlayPause: timer.running ? controller.pause : controller.start,
          onSkip: controller.skipPhase,
        ),
        if (session.purpose case final purpose? when purpose.isNotEmpty) ...[
          const SizedBox(height: Gap.lg),
          Text(
            purpose,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: Gap.lg),
        FilledButton.icon(
          onPressed: () =>
              reportSaveFailure(context, () => actions.finish(session.id)),
          icon: const Icon(Icons.check),
          label: Text(l10n.pomodoroFinish),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () =>
                  reportSaveFailure(context, () => actions.cancel(session.id)),
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
      ],
    );
  }
}

/// Play, pause and skip. Every callback null means the clock is locked.
class _Controls extends StatelessWidget {
  const _Controls({this.running = false, this.onPlayPause, this.onSkip});

  final bool running;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          iconSize: 28,
          onPressed: running ? onPlayPause : null,
          icon: const Icon(Icons.pause),
          tooltip: l10n.pomodoroPause,
        ),
        const SizedBox(width: Gap.lg),
        IconButton.filled(
          iconSize: 36,
          onPressed: onPlayPause,
          icon: Icon(running ? Icons.pause : Icons.play_arrow),
          tooltip: running ? l10n.pomodoroPause : l10n.pomodoroStart,
        ),
        const SizedBox(width: Gap.lg),
        IconButton.filledTonal(
          iconSize: 28,
          onPressed: onSkip,
          icon: const Icon(Icons.skip_next),
          tooltip: l10n.pomodoroSkip,
        ),
      ],
    );
  }
}

/// Which sound is playing, and the way to add one.
class _SoundBar extends ConsumerWidget {
  const _SoundBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(focusSoundActionsProvider);
    final sounds = ref.watch(focusSoundsProvider).valueOrNull ?? const [];
    final chosen = ref.watch(chosenSoundProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: chosen?.id ?? '',
              decoration: InputDecoration(labelText: l10n.pomodoroSound),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(l10n.pomodoroSoundNone),
                ),
                for (final sound in sounds)
                  DropdownMenuItem(value: sound.id, child: Text(sound.name)),
              ],
              onChanged: (value) => actions.choose(value ?? ''),
            ),
          ),
          const SizedBox(width: Gap.sm),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.pomodoroSoundAdd,
            onPressed: () async {
              final draft = await showFocusSoundForm(context);
              if (draft == null || !context.mounted) return;
              await reportSaveFailure(context, () => actions.add(draft));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.pomodoroSoundEdit,
            // Only what is playing can be edited: a library of three rain
            // recordings does not need a screen of its own, and the one in
            // the dropdown is the one the user is thinking about.
            onPressed: chosen == null
                ? null
                : () => _edit(context, ref, chosen),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    FocusSound sound,
  ) async {
    final actions = ref.read(focusSoundActionsProvider);
    final draft = await showFocusSoundForm(
      context,
      existing: sound,
      onDelete: () => actions.delete(sound.id),
    );
    if (draft == null || !context.mounted) return;
    await reportSaveFailure(context, () => actions.update(sound.id, draft));
  }
}

/// The player, watching only the choice — never the countdown.
class _Player extends ConsumerWidget {
  const _Player();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final chosen = ref.watch(chosenSoundProvider);
    final library = ref.watch(focusSoundsProvider).valueOrNull ?? const [];

    if (chosen == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
        child: Text(
          library.isEmpty
              ? l10n.pomodoroSoundLibraryEmpty
              : l10n.pomodoroSoundNone,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
      child: FocusSoundPlayer(sound: chosen),
    );
  }
}

/// The right pane: what has been run, and the way to start something new.
class _HistoryPane extends ConsumerWidget {
  const _HistoryPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(pomodoroListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.pomodoroHistory),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.pomodoroNew),
            onPressed: () async {
              final draft = await showPomodoroForm(context);
              if (draft == null || !context.mounted) return;
              await reportSaveFailure(
                context,
                () => ref.read(pomodoroActionsProvider).create(draft),
              );
            },
          ),
        ),
        const SizedBox(height: Gap.md),
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
    final selected = ref.watch(selectedSessionIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in page.sessions)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: Card(
              // The one on the clock is marked, because the two panes are
              // on screen together and nothing else says which is which.
              color: session.id == selected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : null,
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
