import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/features/pomodoro/domain/pomodoro_session.dart';
import 'package:nisabit/features/pomodoro/domain/pomodoro_stats.dart';

void main() {
  PomodoroSession session({
    int id = 1,
    String name = 'Escribir',
    String? category,
    int cycles = 4,
    int focusDuration = 25,
    int breakDuration = 5,
    int completedCycles = 0,
    PomodoroStatus status = PomodoroStatus.pending,
    DateTime? startedAt,
  }) => PomodoroSession(
    id: id,
    name: name,
    category: category,
    cycles: cycles,
    focusDuration: focusDuration,
    breakDuration: breakDuration,
    completedCycles: completedCycles,
    status: status,
    startedAt: startedAt ?? DateTime(2026, 3, 11, 9),
  );

  group('PomodoroStatus.parse', () {
    test('accepts every canonical name', () {
      expect(PomodoroStatus.parse('PENDING'), PomodoroStatus.pending);
      expect(PomodoroStatus.parse('RUNNING'), PomodoroStatus.running);
      expect(PomodoroStatus.parse('PAUSED'), PomodoroStatus.paused);
      expect(PomodoroStatus.parse('COMPLETED'), PomodoroStatus.completed);
      expect(PomodoroStatus.parse('CANCELLED'), PomodoroStatus.cancelled);
    });

    test('normalizes casing and blanks to pending', () {
      expect(PomodoroStatus.parse(' running '), PomodoroStatus.running);
      expect(PomodoroStatus.parse(null), PomodoroStatus.pending);
    });

    test('rejects the phantom CYCLE_COMPLETED the old timer used to send', () {
      // The previous client sent this on every focus phase and it silently
      // did nothing, which is why completed cycles never advanced.
      expect(
        () => PomodoroStatus.parse('CYCLE_COMPLETED'),
        throwsArgumentError,
      );
    });
  });

  group('validation', () {
    test('requires a name', () {
      expect(() => session(name: '  '), throwsArgumentError);
    });

    test('bounds the cycles to one hundred', () {
      expect(() => session(cycles: 0), throwsArgumentError);
      expect(() => session(cycles: 101), throwsArgumentError);
      expect(session(cycles: 100).cycles, 100);
    });

    test('bounds the focus minutes', () {
      expect(() => session(focusDuration: 0), throwsArgumentError);
      expect(() => session(focusDuration: 1441), throwsArgumentError);
    });

    test('allows a session with no break at all', () {
      expect(session(breakDuration: 0).breakDuration, 0);
    });
  });

  group('progress', () {
    test('is cancelled whatever the cycles say', () {
      expect(
        session(status: PomodoroStatus.cancelled, completedCycles: 2).progress,
        SessionProgress.cancelled,
      );
    });

    test('is done when the status says so', () {
      expect(
        session(status: PomodoroStatus.completed).progress,
        SessionProgress.completed,
      );
    });

    test('is done when the cycles were all served', () {
      expect(
        session(cycles: 4, completedCycles: 4).progress,
        SessionProgress.completed,
      );
    });

    test('is under way after the first cycle', () {
      expect(session(completedCycles: 1).progress, SessionProgress.inProgress);
    });

    test('is pending before anything happened', () {
      expect(session().progress, SessionProgress.pending);
    });
  });

  group('completeCycle', () {
    test('adds one cycle', () {
      expect(session().completeCycle().completedCycles, 1);
    });

    test('closes the session on the last cycle', () {
      final last = session(cycles: 2, completedCycles: 1).completeCycle();

      expect(last.completedCycles, 2);
      expect(last.status, PomodoroStatus.completed);
    });

    test('never runs past the planned cycles', () {
      final over = session(cycles: 2, completedCycles: 2).completeCycle();

      expect(over.completedCycles, 2);
    });
  });

  group('finish and cancel', () {
    test('finishing serves every remaining cycle', () {
      final done = session(cycles: 4, completedCycles: 1).finish();

      expect(done.completedCycles, 4);
      expect(done.status, PomodoroStatus.completed);
    });

    test('cancelling leaves the cycles already served alone', () {
      final cancelled = session(completedCycles: 2).cancel();

      expect(cancelled.status, PomodoroStatus.cancelled);
      expect(cancelled.completedCycles, 2);
    });
  });

  group('focusMinutes', () {
    test('counts only the cycles actually served', () {
      expect(session(focusDuration: 25, completedCycles: 3).focusMinutes, 75);
      expect(session(completedCycles: 0).focusMinutes, 0);
    });
  });

  group('PomodoroStats', () {
    test('is empty without sessions', () {
      final stats = PomodoroStats.from(const []);

      expect(stats.isEmpty, isTrue);
      expect(stats.focusMinutes, 0);
      expect(stats.cycles, 0);
    });

    test('adds up the focus minutes and the cycles', () {
      final stats = PomodoroStats.from([
        session(id: 1, completedCycles: 2, focusDuration: 25),
        session(id: 2, completedCycles: 3, focusDuration: 30),
      ]);

      expect(stats.focusMinutes, 2 * 25 + 3 * 30);
      expect(stats.cycles, 5);
    });

    test('leaves out sessions that never served a cycle', () {
      final stats = PomodoroStats.from([
        session(id: 1, category: 'Trabajo', completedCycles: 2),
        session(id: 2, category: 'Trabajo', completedCycles: 0),
      ]);

      expect(stats.byCategory, {'Trabajo': 50});
    });

    test('files a session with no category under its own label', () {
      final stats = PomodoroStats.from([session(completedCycles: 1)]);

      expect(stats.byCategory.keys.single, PomodoroStats.uncategorized);
    });

    test('groups the minutes by the day the session started', () {
      final stats = PomodoroStats.from([
        session(id: 1, completedCycles: 1, startedAt: DateTime(2026, 3, 11, 9)),
        session(id: 2, completedCycles: 2, startedAt: DateTime(2026, 3, 11, 18)),
        session(id: 3, completedCycles: 1, startedAt: DateTime(2026, 3, 12, 9)),
      ]);

      expect(stats.perDay, [
        (day: DateTime(2026, 3, 11), minutes: 75),
        (day: DateTime(2026, 3, 12), minutes: 25),
      ]);
    });
  });
}
