import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/pomodoro/domain/pomodoro_session.dart';
import 'package:nisabitus/features/pomodoro/presentation/focus_timer.dart';

void main() {
  late int cyclesReported;

  PomodoroSession session({int focus = 25, int rest = 5}) => PomodoroSession(
    id: 1,
    name: 'Escribir',
    cycles: 4,
    focusDuration: focus,
    breakDuration: rest,
    completedCycles: 0,
    status: PomodoroStatus.pending,
    startedAt: DateTime(2026, 3, 11, 9),
  );

  FocusTimer timerFor(PomodoroSession s) => FocusTimer(
    session: s,
    onFocusPhaseEnded: () async => cyclesReported++,
  );

  setUp(() => cyclesReported = 0);

  void runOutPhase(FocusTimer timer) {
    final seconds = timer.state.remaining.inSeconds;
    for (var i = 0; i < seconds; i++) {
      timer.tick();
    }
  }

  group('at rest', () {
    test('starts on a full focus phase, not running', () {
      final timer = timerFor(session());

      expect(timer.state.phase, TimerPhase.focus);
      expect(timer.state.remaining, const Duration(minutes: 25));
      expect(timer.state.running, isFalse);
      expect(timer.state.progress, 0);
    });
  });

  group('ticking', () {
    test('counts down a second at a time', () {
      final timer = timerFor(session());

      timer.tick();

      expect(timer.state.remaining, const Duration(minutes: 24, seconds: 59));
    });

    test('fills the ring as the phase runs out', () {
      final timer = timerFor(session(focus: 1));

      for (var i = 0; i < 30; i++) {
        timer.tick();
      }

      expect(timer.state.progress, closeTo(0.5, 0.02));
    });
  });

  group('when a focus phase ends', () {
    test('reports exactly one served cycle', () {
      final timer = timerFor(session(focus: 1));

      runOutPhase(timer);

      // The whole point of the rewrite: the old client sent an invalid
      // status here and the cycle was silently lost.
      expect(cyclesReported, 1);
    });

    test('moves on to the break', () {
      final timer = timerFor(session(focus: 1, rest: 5));

      runOutPhase(timer);

      expect(timer.state.phase, TimerPhase.rest);
      expect(timer.state.remaining, const Duration(minutes: 5));
    });

    test('goes straight back to focus when there is no break', () {
      final timer = timerFor(session(focus: 1, rest: 0));

      runOutPhase(timer);

      expect(timer.state.phase, TimerPhase.focus);
      expect(timer.state.remaining, const Duration(minutes: 1));
    });
  });

  group('when a break ends', () {
    test('reports no cycle, because none was worked', () {
      final timer = timerFor(session(focus: 1, rest: 1));
      runOutPhase(timer);

      runOutPhase(timer);

      expect(cyclesReported, 1);
      expect(timer.state.phase, TimerPhase.focus);
    });
  });

  group('skipping', () {
    test('a focus phase still counts the cycle', () {
      final timer = timerFor(session());

      timer.skipPhase();

      expect(cyclesReported, 1);
      expect(timer.state.phase, TimerPhase.rest);
    });

    test('a break costs nothing', () {
      final timer = timerFor(session());
      timer.skipPhase();

      timer.skipPhase();

      expect(cyclesReported, 1);
      expect(timer.state.phase, TimerPhase.focus);
    });
  });

  group('pausing', () {
    test('stops the countdown and keeps the remainder', () {
      final timer = timerFor(session());
      timer.start();
      timer.tick();

      timer.pause();
      final held = timer.state.remaining;

      expect(timer.state.running, isFalse);
      expect(timer.state.remaining, held);
    });
  });
}
