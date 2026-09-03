/// A day of the week.
///
/// In `core/` rather than inside a feature: a calendar concept belongs to
/// nobody in particular, and habits, routines and anything else that repeats
/// weekly all need the same one. A second copy would be a second encoding,
/// and the two would disagree the first time either changed.
enum Weekday {
  monday('MONDAY'),
  tuesday('TUESDAY'),
  wednesday('WEDNESDAY'),
  thursday('THURSDAY'),
  friday('FRIDAY'),
  saturday('SATURDAY'),
  sunday('SUNDAY');

  const Weekday(this.wireName);

  final String wireName;

  /// DateTime.weekday is 1 for Monday through 7 for Sunday.
  static Weekday of(DateTime day) => Weekday.values[day.weekday - 1];

  static Weekday parse(String value) {
    final normalized = value.trim().toUpperCase();
    for (final day in Weekday.values) {
      if (day.wireName == normalized) return day;
    }
    throw ArgumentError.value(value, 'value', 'Unknown weekday');
  }

  /// Serializes a selection for storage as a single column.
  static String encode(Set<Weekday> days) =>
      days.map((day) => day.wireName).join(',');

  /// Reads back a stored selection. Blank means no restriction.
  static Set<Weekday> decode(String? stored) {
    final raw = stored?.trim() ?? '';
    if (raw.isEmpty) return const {};

    return raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(Weekday.parse)
        .toSet();
  }
}
