import '../../../core/time/date_range.dart';

/// How a night reads once its hours are known.
///
/// Quality is derived, never stored: the same night can only ever have one
/// verdict, and it follows from the hours.
enum SleepQuality {
  optimal,
  acceptable,
  poor;

  static SleepQuality forHours(double hours) {
    if (hours >= 7 && hours <= 9) return SleepQuality.optimal;
    if (hours >= 6 && hours <= 10) return SleepQuality.acceptable;
    return SleepQuality.poor;
  }
}

/// How many hours were slept on one night.
///
/// At most one record per day; registering the same day again replaces it.
class SleepLog {
  SleepLog({required this.id, required this.hours, required DateTime date})
    : date = dateOnly(date) {
    if (hours < 0 || hours > 24) {
      throw ArgumentError.value(
        hours,
        'hours',
        'The hours slept must be between 0 and 24',
      );
    }
  }

  final int id;
  final double hours;
  final DateTime date;

  SleepQuality get quality => SleepQuality.forHours(hours);
}
