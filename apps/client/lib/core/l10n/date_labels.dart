import '../../l10n/app_localizations.dart';

/// Date wording shared by every module.
///
/// Lives in core because the week strip, the habit rows and the charts all
/// need the same abbreviations, and none of them owns the others.
extension DateLabels on AppLocalizations {
  /// The one-letter abbreviation for a date's weekday.
  ///
  /// DateTime.weekday is 1 for Monday through 7 for Sunday.
  String weekdayLetter(DateTime day) => switch (day.weekday) {
    DateTime.monday => weekdayShortMonday,
    DateTime.tuesday => weekdayShortTuesday,
    DateTime.wednesday => weekdayShortWednesday,
    DateTime.thursday => weekdayShortThursday,
    DateTime.friday => weekdayShortFriday,
    DateTime.saturday => weekdayShortSaturday,
    _ => weekdayShortSunday,
  };
}
