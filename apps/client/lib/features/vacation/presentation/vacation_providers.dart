import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../habits/presentation/habit_providers.dart';
import '../../streaks/presentation/streak_providers.dart';
import '../data/drift_vacation_repository.dart';
import '../domain/vacation.dart';
import '../domain/vacation_repository.dart';

final vacationRepositoryProvider = Provider<VacationRepository>(
  (ref) => DriftVacationRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final vacationRevisionProvider = StateProvider<int>((ref) => 0);

/// Every break, oldest first.
final vacationPeriodsProvider = FutureProvider<List<VacationPeriod>>((ref) {
  ref.watch(vacationRevisionProvider);

  return ref.watch(vacationRepositoryProvider).list();
});

/// The breaks as one calendar, for the code that asks about a day.
final vacationCalendarProvider = FutureProvider<VacationCalendar>((ref) async {
  return VacationCalendar(await ref.watch(vacationPeriodsProvider.future));
});

/// Whether today is paused.
///
/// Read all over the app, so it answers with a plain bool and defaults to
/// "not paused" while the query is in flight: a screen that flickered into a
/// paused state on every rebuild would be worse than one that arrives a
/// frame late.
final pausedTodayProvider = Provider<bool>((ref) {
  final today = ref.watch(todayProvider);
  final calendar = ref.watch(vacationCalendarProvider).valueOrNull;

  return calendar?.covers(today) ?? false;
});

/// The break that is still going, if the user is away.
final openVacationProvider = Provider<VacationPeriod?>(
  (ref) => ref.watch(vacationCalendarProvider).valueOrNull?.openPeriod,
);

/// Write operations, kept out of the widgets.
class VacationActions {
  VacationActions(this._ref);

  final Ref _ref;

  VacationRepository get _repository => _ref.read(vacationRepositoryProvider);
  DateTime get _today => _ref.read(todayProvider);

  Future<void> start() async {
    await _repository.start(_today);
    _invalidate();
  }

  Future<void> end() async {
    await _repository.end(_today);
    _invalidate();
  }

  Future<void> add(VacationDraft draft) async {
    await _repository.add(draft);
    _invalidate();
  }

  Future<void> update(String id, VacationDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _invalidate();
  }

  /// Habits and streaks are bumped along with the breaks.
  ///
  /// What a day means changes the moment a break is written down, and both
  /// of those screens are showing a day.
  void _invalidate() {
    _ref.read(vacationRevisionProvider.notifier).update((value) => value + 1);
    _ref.read(habitsRevisionProvider.notifier).update((value) => value + 1);
    _ref.read(streaksRevisionProvider.notifier).update((value) => value + 1);
  }
}

final vacationActionsProvider = Provider<VacationActions>(VacationActions.new);
