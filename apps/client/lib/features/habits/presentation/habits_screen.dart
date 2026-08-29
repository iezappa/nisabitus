import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../streaks/presentation/streaks_section.dart';
import '../domain/habit.dart';
import '../domain/habit_frequency.dart';
import 'habit_labels.dart';
import 'habit_providers.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_form_dialog.dart';

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

  HabitFrequency get _currentFrequency =>
      HabitFrequency.values[_tabs.index];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.habitsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            for (final frequency in HabitFrequency.values)
              Tab(text: l10n.frequencyName(frequency)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final draft = await showHabitForm(
            context,
            initialFrequency: _currentFrequency,
          );
          if (draft != null) {
            await ref.read(habitActionsProvider).create(draft);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.habitNew),
      ),
      body: Column(
        children: [
          const StreaksSection(),
          const Divider(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                for (final frequency in HabitFrequency.values)
                  _HabitList(frequency: frequency),
              ],
            ),
          ),
        ],
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

    return habits.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          '$error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (items) => items.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.checklist_rtl_outlined,
                title: l10n.habitsEmpty,
                hint: l10n.habitsEmptyHint,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final habit = items[index];
                return HabitCard(
                  habit: habit,
                  day: today,
                  onToggle: () => actions.toggle(habit.id),
                  onCancel: () =>
                      actions.changeStatus(habit.id, HabitStatus.cancelled),
                  onRevert: () =>
                      actions.changeStatus(habit.id, HabitStatus.pending),
                  onEdit: () async {
                    final draft = await showHabitForm(context, existing: habit);
                    if (draft != null) await actions.update(habit.id, draft);
                  },
                  onDelete: () async {
                    if (await confirmDelete(context, habit.name)) {
                      await actions.delete(habit.id);
                    }
                  },
                );
              },
            ),
    );
  }
}
