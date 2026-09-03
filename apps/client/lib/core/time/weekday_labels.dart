import '../../l10n/app_localizations.dart';
import 'weekday.dart';

/// The words a [Weekday] is read as.
///
/// Beside the enum in `core/` rather than inside whichever feature happened
/// to need it first: habits restrict themselves to weekdays, routines
/// prescribe on them, and a second copy of these strings would be a second
/// set of abbreviations for the same seven days.
extension WeekdayLabels on AppLocalizations {
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
  String weekdayList(Set<Weekday> days) =>
      Weekday.values.where(days.contains).map(weekdayShort).join(' ');
}
