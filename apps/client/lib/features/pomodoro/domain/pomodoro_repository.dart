import '../../../core/time/date_range.dart';
import 'pomodoro_draft.dart';
import 'pomodoro_session.dart';
import 'pomodoro_stats.dart';

/// A slice of the session list, with enough context to render the pager.
class PomodoroPage {
  const PomodoroPage({
    required this.sessions,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<PomodoroSession> sessions;
  final int total;
  final int page;
  final int pageSize;

  int get pageCount => (total / pageSize).ceil();
}

/// The port the pomodoro module talks to.
abstract interface class PomodoroRepository {
  /// Sessions newest first, five to a page.
  Future<PomodoroPage> list({int page, int pageSize});

  Future<PomodoroSession?> byId(int id);

  Future<PomodoroSession> create(PomodoroDraft draft, {DateTime? startedAt});

  Future<PomodoroSession> update(int id, PomodoroDraft draft);

  Future<void> delete(int id);

  /// Records one finished focus phase. This is what the timer calls.
  Future<PomodoroSession> completeCycle(int id);

  /// Moves the session to [status] without touching its cycles.
  Future<PomodoroSession> setStatus(int id, PomodoroStatus status);

  /// Closes the session early, counting every planned cycle as served.
  Future<PomodoroSession> finish(int id);

  Future<PomodoroSession> cancel(int id);

  /// Figures for the sessions started inside [range].
  Future<PomodoroStats> statsFor(DateRange range);
}
