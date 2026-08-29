/// Where a focus session stands.
enum PomodoroStatus {
  pending('PENDING'),
  running('RUNNING'),
  paused('PAUSED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const PomodoroStatus(this.wireName);

  final String wireName;

  /// Parses a stored or supplied value. Blank falls back to pending.
  ///
  /// Deliberately strict: the previous client sent `CYCLE_COMPLETED` at the
  /// end of every focus phase, which is not a status. Because that write was
  /// silently ignored, completed cycles never advanced. Rejecting it loudly
  /// is what keeps that class of bug from coming back.
  static PomodoroStatus parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return PomodoroStatus.pending;

    for (final status in PomodoroStatus.values) {
      if (status.wireName == normalized) return status;
    }
    throw ArgumentError.value(value, 'value', 'Unknown pomodoro status');
  }
}

/// How a session reads in the list, which is not the same as its status: a
/// session whose cycles are all served is finished even if nobody said so.
enum SessionProgress { pending, inProgress, completed, cancelled }

/// A focus session made of alternating focus and break phases.
class PomodoroSession {
  PomodoroSession({
    required this.id,
    required String name,
    required this.cycles,
    required this.focusDuration,
    required this.breakDuration,
    required this.completedCycles,
    required this.status,
    required this.startedAt,
    this.category,
    this.purpose,
  }) : name = _validateName(name) {
    _bound(cycles, 'cycles', 1, 100);
    _bound(focusDuration, 'focusDuration', 1, 1440);
    _bound(breakDuration, 'breakDuration', 0, 1440);
    _bound(completedCycles, 'completedCycles', 0, 100);
  }

  final int id;
  final String name;
  final String? category;
  final String? purpose;
  final int cycles;
  final int focusDuration;
  final int breakDuration;
  final int completedCycles;
  final PomodoroStatus status;
  final DateTime startedAt;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  static void _bound(int value, String field, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError.value(
        value,
        field,
        'Must be between $min and $max',
      );
    }
  }

  SessionProgress get progress {
    if (status == PomodoroStatus.cancelled) return SessionProgress.cancelled;
    if (status == PomodoroStatus.completed || completedCycles >= cycles) {
      return SessionProgress.completed;
    }
    return completedCycles > 0
        ? SessionProgress.inProgress
        : SessionProgress.pending;
  }

  /// Minutes of focus actually served, which is what the statistics count.
  int get focusMinutes => completedCycles * focusDuration;

  /// Records one finished focus phase.
  ///
  /// This is what the timer calls when a focus phase ends. Serving the last
  /// planned cycle closes the session, so finishing needs no separate tap.
  PomodoroSession completeCycle() {
    if (completedCycles >= cycles) return this;

    final next = completedCycles + 1;
    return copyWith(
      completedCycles: next,
      status: next >= cycles ? PomodoroStatus.completed : status,
    );
  }

  /// Closes the session early, counting every planned cycle as served.
  PomodoroSession finish() =>
      copyWith(completedCycles: cycles, status: PomodoroStatus.completed);

  /// Abandons the session, keeping whatever was already served.
  PomodoroSession cancel() => copyWith(status: PomodoroStatus.cancelled);

  PomodoroSession copyWith({
    int? completedCycles,
    PomodoroStatus? status,
  }) => PomodoroSession(
    id: id,
    name: name,
    category: category,
    purpose: purpose,
    cycles: cycles,
    focusDuration: focusDuration,
    breakDuration: breakDuration,
    completedCycles: completedCycles ?? this.completedCycles,
    status: status ?? this.status,
    startedAt: startedAt,
  );
}
