import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_session.dart';

/// Which half of the cycle is running.
enum TimerPhase { focus, rest }

/// What the timer looks like right now.
class FocusTimerState {
  const FocusTimerState({
    required this.phase,
    required this.remaining,
    required this.total,
    required this.running,
  });

  final TimerPhase phase;
  final Duration remaining;
  final Duration total;
  final bool running;

  /// Zero to one, for the ring.
  double get progress =>
      total.inSeconds == 0 ? 0 : 1 - (remaining.inSeconds / total.inSeconds);

  FocusTimerState copyWith({
    TimerPhase? phase,
    Duration? remaining,
    Duration? total,
    bool? running,
  }) => FocusTimerState(
    phase: phase ?? this.phase,
    remaining: remaining ?? this.remaining,
    total: total ?? this.total,
    running: running ?? this.running,
  );
}

/// The countdown, which lives only in the client.
///
/// The second-by-second value is never persisted: only finished cycles are,
/// and they go through [onFocusPhaseEnded]. Closing the app mid-phase loses
/// the partial minute, which is the right trade for not writing to disk
/// every second.
class FocusTimer extends StateNotifier<FocusTimerState> {
  FocusTimer({required this.session, required this.onFocusPhaseEnded})
    : super(
        FocusTimerState(
          phase: TimerPhase.focus,
          remaining: Duration(minutes: session.focusDuration),
          total: Duration(minutes: session.focusDuration),
          running: false,
        ),
      );

  final PomodoroSession session;

  /// Called exactly once per finished focus phase.
  ///
  /// This is the connection the spec asks for: the old client sent a bogus
  /// `CYCLE_COMPLETED` status here, which was silently dropped, so served
  /// cycles never advanced.
  final Future<void> Function() onFocusPhaseEnded;

  Timer? _ticker;

  void start() {
    if (state.running) return;
    state = state.copyWith(running: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(running: false);
  }

  /// Advances one second. Exposed so the behaviour can be tested without
  /// waiting in real time.
  void tick() {
    if (state.remaining.inSeconds <= 1) {
      _advancePhase();
      return;
    }
    state = state.copyWith(
      remaining: state.remaining - const Duration(seconds: 1),
    );
  }

  /// Ends the current phase now.
  void skipPhase() => _advancePhase();

  void _advancePhase() {
    final wasFocus = state.phase == TimerPhase.focus;
    if (wasFocus) {
      onFocusPhaseEnded();
    }

    final next = wasFocus ? TimerPhase.rest : TimerPhase.focus;
    final minutes = next == TimerPhase.focus
        ? session.focusDuration
        : session.breakDuration;

    // A session configured with no break goes straight back to focusing.
    if (minutes == 0 && next == TimerPhase.rest) {
      state = state.copyWith(
        phase: TimerPhase.focus,
        remaining: Duration(minutes: session.focusDuration),
        total: Duration(minutes: session.focusDuration),
      );
      return;
    }

    state = state.copyWith(
      phase: next,
      remaining: Duration(minutes: minutes),
      total: Duration(minutes: minutes),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
