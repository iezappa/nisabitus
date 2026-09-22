import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/save_failure.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../streaks/presentation/streaks_section.dart';
import '../../vacation/presentation/vacation_providers.dart';
import '../domain/habit.dart';
import '../domain/habit_frequency.dart';
import 'habit_labels.dart';
import 'habit_providers.dart';
import 'progress_tab.dart';
import 'widgets/habit_form_dialog.dart';
import 'widgets/habit_row.dart';

/// The Hábitos tab: streaks on top, recurring habits below, split into one
/// tab per frequency.
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: HabitFrequency.values.length,
    vsync: this,
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  HabitFrequency get _currentFrequency => HabitFrequency.values[_tabs.index];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModuleScaffold(
      title: l10n.habitsTitle,
      // The streaks band and the frequency tabs steer the list; neither says
      // anything about the window the progress side is looking at.
      listOnly: Column(
        children: [
          const _PausedNotice(),
          const StreaksSection(),
          // The streaks band and the frequency tabs are two different
          // controls; sitting flush they read as one, and the tabs look like
          // they belong to the streaks above them.
          const SizedBox(height: Gap.lg),
          TabBar(
            controller: _tabs,
            tabs: [
              for (final frequency in HabitFrequency.values)
                Tab(text: l10n.frequencyName(frequency)),
            ],
          ),
        ],
      ),
      list: TabBarView(
        controller: _tabs,
        children: [
          for (final frequency in HabitFrequency.values)
            _HabitList(frequency: frequency),
        ],
      ),
      progress: const ProgressTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final draft = await showHabitForm(
            context,
            initialFrequency: _currentFrequency,
            categories:
                ref.read(habitCategoriesProvider).valueOrNull ?? const [],
          );
          if (draft == null || !context.mounted) return;
          await reportSaveFailure(
            context,
            () => ref.read(habitActionsProvider).create(draft),
          );
        },
        tooltip: l10n.habitNew,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitList extends ConsumerWidget {
  const _HabitList({required this.frequency});

  final HabitFrequency frequency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final habits = ref.watch(habitsForFrequencyProvider(frequency));
    final actions = ref.read(habitActionsProvider);
    final today = ref.watch(habitDayProvider);
    final paused = ref.watch(pausedTodayProvider);

    return AsyncSection(
      value: habits,
      builder: (items) {
        if (items.isEmpty) {
          // Centred while there is room, scrollable when there is not: the
          // strip above grows when the user is away, and on a short window
          // a plain Center has nowhere to put what it cannot fit.
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: EmptyState(
                    icon: Icons.checklist_rtl_outlined,
                    title: l10n.habitsEmpty,
                    hint: l10n.habitsEmptyHint,
                  ),
                ),
              ),
            ),
          );
        }

        final done = items.where((habit) => habit.completed).length;

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          // One extra leading item: the section header with today's count.
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return SectionHeader(
                label: l10n.habitsToday,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: Gap.sm),
                  child: Text(
                    l10n.habitsTodayCount(done, items.length),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              );
            }

            final habit = items[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: HabitRow(
                habit: habit,
                day: today,
                paused: paused,
                onToggle: () => actions.toggle(habit.id),
                onCancel: () =>
                    actions.changeStatus(habit.id, HabitStatus.cancelled),
                onRevert: () =>
                    actions.changeStatus(habit.id, HabitStatus.pending),
                onEdit: () async {
                  final draft = await showHabitForm(
                    context,
                    existing: habit,
                    categories:
                        ref.read(habitCategoriesProvider).valueOrNull ??
                        const [],
                    onDelete: () => actions.delete(habit.id),
                  );
                  if (draft != null) await actions.update(habit.id, draft);
                },
                onDelete: () async {
                  if (await confirmDelete(context, habit.name)) {
                    if (!context.mounted) return;
                    await reportDeleteFailure(
                      context,
                      () => actions.delete(habit.id),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// The strip that says today does not count.
///
/// On the habits screen because this is where the promise is kept: the rows
/// below it have gone quiet and the streaks above it will not break. It
/// carries the way out as well, so an open-ended break cannot be switched on
/// here and only found again in settings.
class _PausedNotice extends ConsumerWidget {
  const _PausedNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(pausedTodayProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final open = ref.watch(openVacationProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.sm, Gap.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.beach_access_outlined,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                l10n.vacationPausedToday,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            // Only while a break is still open: a holiday written down for
            // dates that already have an end is not something to "finish".
            if (open != null)
              TextButton(
                onPressed: () => reportSaveFailure(
                  context,
                  ref.read(vacationActionsProvider).end,
                ),
                child: Text(l10n.vacationEnd),
              ),
          ],
        ),
      ),
    );
  }
}
