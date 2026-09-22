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
import '../../../core/database/database_provider.dart';
import '../../../core/time/date_range.dart';
import '../data/activity_counts.dart';
import '../domain/activity_grid.dart';
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

  final open = tasks.where((task) => !task.countsAsDone).toList();

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

/// How many weeks of squares the grid shows.
///
/// Half a year. Fifty-two would be the familiar shape but it cannot be read
/// on a phone without scrolling past most of it, and this grid answers "have
/// I kept it up lately" rather than "what did I do last spring".
const activityWeeks = 26;

final activityCountsProvider = Provider<ActivityCounts>(
  (ref) => ActivityCounts(ref.watch(databaseProvider)),
);

/// The activity grid for the window ending today.
///
/// Watches every module's revision, so ticking a habit or writing down a
/// meal fills its square without the panel being reopened.
final activityGridProvider = FutureProvider<ActivityGrid>((ref) async {
  ref.watch(habitsRevisionProvider);
  ref.watch(todoRevisionProvider);
  ref.watch(journalRevisionProvider);
  ref.watch(sleepRevisionProvider);

  final today = ref.watch(todayProvider);
  // Counted back in whole weeks rather than in days, so the grid is exactly
  // [activityWeeks] columns wide however far into the week today is: a
  // window of 182 days starting on a Thursday is 27 partial columns, and
  // the caption would be claiming a width the grid does not have.
  final range = DateRange(
    DateTime(today.year, today.month, today.day - (activityWeeks - 1) * 7),
    today,
  );

  return ActivityGrid.from(
    range,
    await ref.watch(activityCountsProvider).perDay(range),
    // Weeks start on Monday here, as they do everywhere else in the app.
    firstWeekday: DateTime.monday,
  );
});
