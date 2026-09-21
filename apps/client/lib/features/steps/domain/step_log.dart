import '../../../core/time/date_range.dart';

/// The most steps a day is allowed to hold.
///
/// A hundred thousand is about seventy kilometres on foot. The ceiling is
/// here rather than in the widget because it is a fact about what a day may
/// hold, not about how the form looks — and a field with no ceiling is a
/// field where a slipped keystroke silently rewrites a month of charts.
const maxDailySteps = 100000;

/// How many steps were walked on one day.
///
/// One row per day; writing the same day again replaces it. The number grows
/// through the day, and a second row for the same date would be a day walked
/// twice.
class StepLog {
  StepLog({required this.id, required this.steps, required DateTime date})
    : date = dateOnly(date) {
    if (steps < 0 || steps > maxDailySteps) {
      throw ArgumentError.value(
        steps,
        'steps',
        'The steps must be between 0 and $maxDailySteps',
      );
    }
  }

  final String id;
  final int steps;
  final DateTime date;
}

/// The daily step target.
class StepGoal {
  StepGoal({required this.steps}) {
    if (steps <= 0 || steps > maxDailySteps) {
      throw ArgumentError.value(
        steps,
        'steps',
        'The target must be between 1 and $maxDailySteps',
      );
    }
  }

  /// What a fresh install starts on.
  ///
  /// Eight thousand rather than the famous ten: the ten came from the brand
  /// name of a 1960s Japanese pedometer, and what evidence there is puts the
  /// benefit levelling off well below it. A starting point, changed from the
  /// form like every other target here.
  static StepGoal get fallback => StepGoal(steps: 8000);

  final int steps;

  /// How far [walked] got towards this, 0 to 1 and capped there.
  ///
  /// Capped because the bar it fills cannot be more than full, and the raw
  /// figure is on screen right beside it for anyone who wants the overshoot.
  double progressFor(int walked) =>
      steps <= 0 ? 0 : (walked / steps).clamp(0.0, 1.0);

  bool isReachedBy(int walked) => walked >= steps;
}
