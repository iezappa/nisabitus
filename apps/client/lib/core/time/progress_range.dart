import 'date_range.dart';

/// The window a progress view looks at.
///
/// The four presets every module shares. They are relative to a reference
/// day rather than calendar boundaries: "month" means the last thirty days,
/// not the current calendar month.
enum ProgressRange {
  day(1),
  week(7),
  month(30),
  year(365);

  const ProgressRange(this.days);

  /// How many days the window spans, including the reference day.
  final int days;

  /// The window every progress view starts on.
  static const defaultRange = ProgressRange.month;

  DateRange toDateRange({DateTime? from}) =>
      DateRange.lastDays(days, from: from ?? DateTime.now());
}
