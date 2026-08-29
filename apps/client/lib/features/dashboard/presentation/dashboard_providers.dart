import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/selected_day_provider.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/habit_providers.dart';
import '../../journal/domain/journal_repository.dart';
import '../../journal/presentation/journal_providers.dart';
import '../../sleep/domain/sleep_log.dart';
import '../../sleep/presentation/sleep_providers.dart';
import '../../todo/domain/task.dart';
import '../../todo/presentation/todo_providers.dart';
import '../domain/task_focus.dart';

/// Everything the panel shows about today, gathered in one place.
class DashboardSummary {
  const DashboardSummary({
    required this.openTasks,
    required this.overdueTasks,
    required this.focus,
    required this.habitsDone,
    required this.habitsTotal,
    required this.sleep,
    required this.journal,
  });

  final int openTasks;
  final int overdueTasks;

  /// The handful of tasks worth doing next.
  final List<Task> focus;

  final int habitsDone;
  final int habitsTotal;

  /// Tonight's record, if there is one.
  final SleepLog? sleep;

  /// Today's entry, if it was written.
  final JournalEntry? journal;

  bool get journalReady => journal != null;
}

/// Loads every module's view of today at once.
///
/// The four queries are independent, so they run together: the panel is the
/// first screen a user sees and has no reason to load in sequence.
final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  // Any write anywhere changes what the panel says.
  ref.watch(habitsRevisionProvider);
  ref.watch(todoRevisionProvider);
  ref.watch(sleepRevisionProvider);
  ref.watch(journalRevisionProvider);

  final today = ref.watch(todayProvider);

  final (tasks, habits, sleep, journal) = await (
    ref.watch(todoRepositoryProvider).allTasks(),
    ref.watch(habitRepositoryProvider).listForDay(today),
    ref.watch(sleepRepositoryProvider).forDay(today),
    ref.watch(journalRepositoryProvider).forDay(today),
  ).wait;

  final open = tasks.where((task) => task.status != TaskStatus.done).toList();

  return DashboardSummary(
    openTasks: open.length,
    overdueTasks: open
        .where((task) => task.dueState(today) == DueState.overdue)
        .length,
    focus: TaskFocus.rank(tasks, today),
    habitsDone: habits
        .where((habit) => habit.completed || habit.status == HabitStatus.done)
        .length,
    habitsTotal: habits.length,
    sleep: sleep,
    journal: journal,
  );
});
