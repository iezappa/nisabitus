import '../../../core/time/date_range.dart';

/// How often a habit is expected to be fulfilled.
///
/// The frequency determines the period a completion belongs to: a single
/// completion marks the habit as done for the whole period, not just for the
/// day it was recorded.
enum HabitFrequency {
  daily('DAILY'),
  weekly('WEEKLY'),
  monthly('MONTHLY'),
  yearly('YEARLY');

  const HabitFrequency(this.wireName);

  /// The canonical stored representation.
  final String wireName;

  /// Parses a stored or user-supplied value.
  ///
  /// Casing and surrounding whitespace are normalized. A null or blank value
  /// falls back to [HabitFrequency.daily]; anything else is rejected.
  static HabitFrequency parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return HabitFrequency.daily;

    for (final frequency in HabitFrequency.values) {
      if (frequency.wireName == normalized) return frequency;
    }
    throw ArgumentError.value(value, 'value', 'Unknown habit frequency');
  }

  /// Only daily and weekly habits can be restricted to specific weekdays.
  bool get supportsRepeatDays =>
      this == HabitFrequency.daily || this == HabitFrequency.weekly;

  /// The range of days a completion recorded on [day] would cover.
  DateRange periodFor(DateTime day) {
    final date = dateOnly(day);
    switch (this) {
      case HabitFrequency.daily:
        return DateRange(date, date);
      case HabitFrequency.weekly:
        // DateTime.weekday is 1 for Monday through 7 for Sunday.
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return DateRange(monday, monday.add(const Duration(days: 6)));
      case HabitFrequency.monthly:
        // Day zero of the next month is the last day of this one.
        return DateRange(
          DateTime(date.year, date.month, 1),
          DateTime(date.year, date.month + 1, 0),
        );
      case HabitFrequency.yearly:
        return DateRange(
          DateTime(date.year, 1, 1),
          DateTime(date.year, 12, 31),
        );
    }
  }
}
