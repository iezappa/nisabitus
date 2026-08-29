import '../../../core/time/date_range.dart';
import 'pomodoro_session.dart';

/// Focus minutes served on one day.
typedef DailyFocusMinutes = ({DateTime day, int minutes});

/// What the pomodoro statistics show over a window.
class PomodoroStats {
  const PomodoroStats._({
    required this.focusMinutes,
    required this.cycles,
    required this.byCategory,
    required this.perDay,
  });

  /// Reads the figures off the sessions started inside the window.
  ///
  /// Only cycles actually served count: a session planned but never run
  /// contributes nothing, which is the honest reading.
  factory PomodoroStats.from(List<PomodoroSession> sessions) {
    final served = sessions.where((s) => s.completedCycles > 0).toList();

    final byCategory = <String, int>{};
    final minutesPerDay = <DateTime, int>{};
    for (final session in served) {
      final label = (session.category ?? '').trim().isEmpty
          ? uncategorized
          : session.category!.trim();
      byCategory[label] = (byCategory[label] ?? 0) + session.focusMinutes;

      final day = dateOnly(session.startedAt);
      minutesPerDay[day] = (minutesPerDay[day] ?? 0) + session.focusMinutes;
    }

    final days = minutesPerDay.keys.toList()..sort();

    return PomodoroStats._(
      focusMinutes: served.fold(0, (sum, s) => sum + s.focusMinutes),
      cycles: served.fold(0, (sum, s) => sum + s.completedCycles),
      byCategory: byCategory,
      perDay: [
        for (final day in days) (day: day, minutes: minutesPerDay[day]!),
      ],
    );
  }

  /// Where sessions without a category are filed.
  static const uncategorized = 'Sin categoría';

  final int focusMinutes;
  final int cycles;
  final Map<String, int> byCategory;
  final List<DailyFocusMinutes> perDay;

  bool get isEmpty => cycles == 0;
}
