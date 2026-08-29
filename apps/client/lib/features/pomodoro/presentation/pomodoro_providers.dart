import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_pomodoro_repository.dart';
import '../domain/pomodoro_draft.dart';
import '../domain/pomodoro_repository.dart';
import '../domain/pomodoro_session.dart';
import '../domain/pomodoro_stats.dart';
import 'focus_timer.dart';

final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => DriftPomodoroRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final pomodoroRevisionProvider = StateProvider<int>((ref) => 0);

/// Zero-based page of the session list.
final pomodoroPageProvider = StateProvider<int>((ref) => 0);

/// The session the focus screen is running, if any.
final selectedSessionIdProvider = StateProvider<int?>((ref) => null);

final pomodoroStatsRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

final pomodoroListProvider = FutureProvider<PomodoroPage>((ref) {
  ref.watch(pomodoroRevisionProvider);

  return ref
      .watch(pomodoroRepositoryProvider)
      .list(page: ref.watch(pomodoroPageProvider));
});

final selectedSessionProvider = FutureProvider<PomodoroSession?>((ref) async {
  ref.watch(pomodoroRevisionProvider);

  final id = ref.watch(selectedSessionIdProvider);
  return id == null ? null : ref.watch(pomodoroRepositoryProvider).byId(id);
});

final pomodoroStatsProvider = FutureProvider<PomodoroStats>((ref) {
  ref.watch(pomodoroRevisionProvider);

  final range = ref
      .watch(pomodoroStatsRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(pomodoroRepositoryProvider).statsFor(range);
});

/// The countdown for the running session, rebuilt when the session changes.
final focusTimerProvider =
    StateNotifierProvider.family<FocusTimer, FocusTimerState, PomodoroSession>(
      (ref, session) => FocusTimer(
        session: session,
        onFocusPhaseEnded: () =>
            ref.read(pomodoroActionsProvider).completeCycle(session.id),
      ),
    );

/// Write operations, kept out of the widgets.
class PomodoroActions {
  PomodoroActions(this._ref);

  final Ref _ref;

  PomodoroRepository get _repository => _ref.read(pomodoroRepositoryProvider);

  Future<void> create(PomodoroDraft draft) async {
    await _repository.create(draft);
    _invalidate();
  }

  Future<void> update(int id, PomodoroDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    if (_ref.read(selectedSessionIdProvider) == id) {
      _ref.read(selectedSessionIdProvider.notifier).state = null;
    }
    _invalidate();
  }

  Future<void> completeCycle(int id) async {
    await _repository.completeCycle(id);
    _invalidate();
  }

  Future<void> finish(int id) async {
    await _repository.finish(id);
    _ref.read(selectedSessionIdProvider.notifier).state = null;
    _invalidate();
  }

  Future<void> cancel(int id) async {
    await _repository.cancel(id);
    _ref.read(selectedSessionIdProvider.notifier).state = null;
    _invalidate();
  }

  Future<void> setStatus(int id, PomodoroStatus status) async {
    await _repository.setStatus(id, status);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(pomodoroRevisionProvider.notifier).update((v) => v + 1);
}

final pomodoroActionsProvider = Provider<PomodoroActions>(PomodoroActions.new);
