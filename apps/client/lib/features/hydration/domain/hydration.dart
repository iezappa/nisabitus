import '../../../core/time/date_range.dart';

/// One drink, written down when it was drunk.
///
/// Water is logged in sips and glasses rather than as one number at the end
/// of the day, so the record is a list of drinks and the day is their sum.
/// A single editable total would be a guess typed at midnight.
class WaterEntry {
  WaterEntry({
    required this.id,
    required DateTime date,
    required this.millilitres,
  }) : date = dateOnly(date) {
    if (millilitres <= 0 || millilitres > maxMillilitres) {
      throw ArgumentError.value(
        millilitres,
        'millilitres',
        'A drink must be between 1 and $maxMillilitres ml',
      );
    }
  }

  /// Five litres in one go is not a drink, it is a typo.
  static const maxMillilitres = 5000;

  final int id;
  final DateTime date;
  final int millilitres;

  WaterEntry copyWith({int? id}) =>
      WaterEntry(id: id ?? this.id, date: date, millilitres: millilitres);
}

/// How much the user is aiming to drink in a day.
class HydrationGoal {
  HydrationGoal({required this.millilitres}) {
    if (millilitres < 0 || millilitres > 20000) {
      throw ArgumentError.value(
        millilitres,
        'millilitres',
        'The daily target must be between 0 and 20000 ml',
      );
    }
  }

  /// Two litres: the number people mean when they say "drink more water".
  /// It is a starting point on a screen that is otherwise empty, not advice —
  /// the app says as much in its own disclaimer.
  static final fallback = HydrationGoal(millilitres: 2000);

  final int millilitres;

  bool get isUnset => millilitres == 0;
}

/// What one day of drinking adds up to, against the target.
class DailyHydration {
  const DailyHydration({
    required this.entries,
    required this.total,
    required this.goal,
  });

  factory DailyHydration.from(List<WaterEntry> entries, HydrationGoal goal) =>
      DailyHydration(
        entries: entries,
        total: entries.fold(0, (sum, entry) => sum + entry.millilitres),
        goal: goal,
      );

  final List<WaterEntry> entries;
  final int total;
  final HydrationGoal goal;

  bool get isEmpty => entries.isEmpty;

  /// How far the day has come, capped at one: past the target the number
  /// keeps climbing but the bar has nowhere left to go.
  double get ratio =>
      goal.millilitres <= 0 ? 0 : (total / goal.millilitres).clamp(0.0, 1.0);

  /// What is left of the day's target. Negative once it is passed, which is
  /// information rather than a problem.
  int get remaining => goal.millilitres - total;
}
