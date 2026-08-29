import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../data/drift_habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_draft.dart';
import '../domain/habit_frequency.dart';
import '../domain/habit_repository.dart';
import '../domain/habit_stats.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => DriftHabitRepository(ref.watch(databaseProvider)),
);

/// The day the habits screen works on. Always today, per the spec.
final habitDayProvider = Provider<DateTime>((ref) => DateTime.now());

/// The habits of the selected frequency tab, hydrated for today.
final habitsForFrequencyProvider =
    FutureProvider.family<List<Habit>, HabitFrequency>((ref, frequency) {
      // Bumping the revision is what makes every open tab reload after a write.
      ref.watch(habitsRevisionProvider);

      return ref
          .watch(habitRepositoryProvider)
          .listForDay(ref.watch(habitDayProvider), frequency: frequency);
    });

/// Incremented after every write so dependent queries refetch.
final habitsRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view is looking at.
final habitProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// Everything the progress view needs, gathered in one place.
final habitStatsProvider = FutureProvider<HabitStats>((ref) async {
  ref.watch(habitsRevisionProvider);

  final repository = ref.watch(habitRepositoryProvider);
  final range = ref
      .watch(habitProgressRangeProvider)
      .toDateRange(from: ref.watch(habitDayProvider));

  // Independent queries, so they run together rather than in sequence.
  final (completions, habitCount, perDay) = await (
    repository.totalCompletions(range),
    repository.countHabits(),
    repository.completionsPerDay(range),
  ).wait;

  return HabitStats(
    completions: completions,
    habitCount: habitCount,
    perDay: perDay,
  );
});

/// Write operations, kept out of the widgets.
class HabitActions {
  HabitActions(this._ref);

  final Ref _ref;

  HabitRepository get _repository => _ref.read(habitRepositoryProvider);
  DateTime get _today => _ref.read(habitDayProvider);

  Future<void> create(HabitDraft draft) async {
    await _repository.create(draft, on: _today);
    _invalidate();
  }

  Future<void> update(int id, HabitDraft draft) async {
    await _repository.update(id, draft, on: _today);
    _invalidate();
  }

  Future<void> toggle(int id) async {
    await _repository.toggleCompletion(id, _today);
    _invalidate();
  }

  Future<void> changeStatus(int id, HabitStatus status) async {
    await _repository.changeStatus(id, status, _today);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(habitsRevisionProvider.notifier).update((value) => value + 1);
}

final habitActionsProvider = Provider<HabitActions>(HabitActions.new);
