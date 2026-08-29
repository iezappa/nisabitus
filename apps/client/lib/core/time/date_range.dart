/// Strips the time component, keeping only year, month and day.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// An inclusive range of whole days.
///
/// Both bounds are normalized to date-only, so a range is a set of calendar
/// days rather than an instant-to-instant interval. This is the unit every
/// progress view in the app works with.
class DateRange {
  DateRange(DateTime start, DateTime end)
    : start = dateOnly(start),
      end = dateOnly(end) {
    if (this.start.isAfter(this.end)) {
      throw ArgumentError(
        'The start date must be earlier than or equal to the end date.',
      );
    }
  }

  /// The default window used across progress views: the last 30 days.
  factory DateRange.lastDays(int days, {DateTime? from}) {
    final end = dateOnly(from ?? DateTime.now());
    return DateRange(end.subtract(Duration(days: days - 1)), end);
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime day) {
    final normalized = dateOnly(day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  int get dayCount => end.difference(start).inDays + 1;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start .. $end)';
}
