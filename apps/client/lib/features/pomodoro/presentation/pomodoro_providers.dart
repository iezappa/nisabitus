import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/preferences/preferences.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_focus_sound_repository.dart';
import '../data/drift_pomodoro_repository.dart';
import '../domain/focus_sound.dart';
import '../domain/focus_sound_repository.dart';
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
final selectedSessionIdProvider = StateProvider<String?>((ref) => null);

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

final focusSoundRepositoryProvider = Provider<FocusSoundRepository>(
  (ref) => DriftFocusSoundRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write to the sound library.
final focusSoundRevisionProvider = StateProvider<int>((ref) => 0);

/// The user's library of things to listen to while focusing.
final focusSoundsProvider = FutureProvider<List<FocusSound>>((ref) {
  ref.watch(focusSoundRevisionProvider);

  return ref.watch(focusSoundRepositoryProvider).list();
});

/// Which sound is chosen, as its id, or the empty string for silence.
///
/// A preference rather than a column on the session: it is a property of
/// this device and this listener, not of the work being done. Someone who
/// restores a backup on a machine with no speakers should not find a track
/// starting up because of what they listened to last month.
final chosenSoundIdProvider = StateNotifierProvider<StringPreference, String>((
  ref,
) {
  return StringPreference(
    ref.watch(sharedPreferencesProvider),
    'pomodoro.sound',
    fallback: '',
  );
});

/// The chosen sound, or null when there is none — or when the one that was
/// chosen has since been deleted.
final chosenSoundProvider = Provider<FocusSound?>((ref) {
  final id = ref.watch(chosenSoundIdProvider);
  if (id.isEmpty) return null;

  final sounds = ref.watch(focusSoundsProvider).valueOrNull ?? const [];
  for (final sound in sounds) {
    if (sound.id == id) return sound;
  }
  return null;
});

/// Write operations on the sound library.
class FocusSoundActions {
  FocusSoundActions(this._ref);

  final Ref _ref;

  FocusSoundRepository get _repository =>
      _ref.read(focusSoundRepositoryProvider);

  Future<void> add(FocusSoundDraft draft) async {
    final sound = await _repository.add(draft);
    _invalidate();
    // Chosen straight away: someone who just went to the trouble of adding
    // a sound wants to hear it, not to pick it out of a list afterwards.
    choose(sound.id);
  }

  Future<void> update(String id, FocusSoundDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    if (_ref.read(chosenSoundIdProvider) == id) choose('');
    _invalidate();
  }

  void choose(String id) => _ref.read(chosenSoundIdProvider.notifier).set(id);

  void _invalidate() =>
      _ref.read(focusSoundRevisionProvider.notifier).update((v) => v + 1);
}

final focusSoundActionsProvider = Provider<FocusSoundActions>(
  FocusSoundActions.new,
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

  Future<void> update(String id, PomodoroDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    if (_ref.read(selectedSessionIdProvider) == id) {
      _ref.read(selectedSessionIdProvider.notifier).state = null;
    }
    _invalidate();
  }

  Future<void> completeCycle(String id) async {
    await _repository.completeCycle(id);
    _invalidate();
  }

  Future<void> finish(String id) async {
    await _repository.finish(id);
    _ref.read(selectedSessionIdProvider.notifier).state = null;
    _invalidate();
  }

  Future<void> cancel(String id) async {
    await _repository.cancel(id);
    _ref.read(selectedSessionIdProvider.notifier).state = null;
    _invalidate();
  }

  Future<void> setStatus(String id, PomodoroStatus status) async {
    await _repository.setStatus(id, status);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(pomodoroRevisionProvider.notifier).update((v) => v + 1);
}

final pomodoroActionsProvider = Provider<PomodoroActions>(PomodoroActions.new);
