import '../../../l10n/app_localizations.dart';
import '../domain/habit.dart';
import '../domain/habit_frequency.dart';

/// Maps domain values to the words the user reads.
///
/// The domain deliberately knows nothing about display strings, so the
/// translation lives here, at the edge.
extension HabitLabels on AppLocalizations {
  String frequencyName(HabitFrequency frequency) => switch (frequency) {
    HabitFrequency.daily => frequencyDaily,
    HabitFrequency.weekly => frequencyWeekly,
    HabitFrequency.monthly => frequencyMonthly,
    HabitFrequency.yearly => frequencyYearly,
  };

  String weekdayShort(Weekday day) => switch (day) {
    Weekday.monday => weekdayShortMonday,
    Weekday.tuesday => weekdayShortTuesday,
    Weekday.wednesday => weekdayShortWednesday,
    Weekday.thursday => weekdayShortThursday,
    Weekday.friday => weekdayShortFriday,
    Weekday.saturday => weekdayShortSaturday,
    Weekday.sunday => weekdayShortSunday,
  };

  /// The chosen weekdays in calendar order, abbreviated.
  String weekdayList(Set<Weekday> days) => Weekday.values
      .where(days.contains)
      .map(weekdayShort)
      .join(' ');
}
