import '../../../l10n/app_localizations.dart';
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
}
