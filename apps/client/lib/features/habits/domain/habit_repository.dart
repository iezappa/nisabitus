import '../../../core/time/date_range.dart';
import 'habit.dart';
import 'habit_draft.dart';
import 'habit_frequency.dart';

/// How many habits were fulfilled on a single day.
typedef DailyCompletionCount = ({DateTime day, int count});

/// The port the habits module talks to.
///
/// The domain owns this contract; persistence implements it. Nothing here
/// mentions a table, a query or a storage engine.
abstract interface class HabitRepository {
  /// Lists the habits as they stand on [day].
  ///
  /// Each habit is hydrated with the state it actually has for that day: a
  /// completion anywhere inside the period its frequency defines marks it as
  /// done. Pass [frequency] to restrict the list to one of the UI tabs.
  Future<List<Habit>> listForDay(DateTime day, {HabitFrequency? frequency});

  Future<Habit> create(HabitDraft draft, {DateTime? on});

  Future<Habit> update(int id, HabitDraft draft, {DateTime? on});

  Future<void> delete(int id);

  /// Flips the habit between fulfilled and pending for the period containing
  /// [day], and returns it hydrated for that same day.
  Future<Habit> toggleCompletion(int id, DateTime day);

  /// Moves the habit to [status] for the period containing [day].
  ///
  /// Becoming done records a completion if the period has none; becoming
  /// pending or cancelled clears the completions of the period.
  Future<Habit> changeStatus(int id, HabitStatus status, DateTime day);

  /// Completions grouped by day, ascending, for the progress chart.
  /// Days with no completion are left out.
  Future<List<DailyCompletionCount>> completionsPerDay(DateRange range);

  /// Total completions recorded inside [range].
  Future<int> totalCompletions(DateRange range);

  /// How many habits exist, used to estimate the success rate.
  Future<int> countHabits();
}
