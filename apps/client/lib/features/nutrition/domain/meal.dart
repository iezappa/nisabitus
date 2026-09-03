/// Which meal of the day something was eaten at.
///
/// The point of recording it is the day read back: four short lists under
/// their own headings say what the day looked like, where one long list of
/// everything only says what it added up to.
enum Meal {
  breakfast('BREAKFAST'),
  lunch('LUNCH'),
  snack('SNACK'),
  dinner('DINNER');

  const Meal(this.wireName);

  /// The canonical stored representation.
  final String wireName;

  /// Parses a stored or user-supplied value.
  ///
  /// Null or blank reads as null rather than as a default: an entry logged
  /// before the app asked which meal it belonged to has no answer, and
  /// picking one for it would put food on the record nobody ate at that hour.
  static Meal? parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return null;

    for (final meal in Meal.values) {
      if (meal.wireName == normalized) return meal;
    }
    throw ArgumentError.value(value, 'value', 'Unknown meal');
  }

  /// The meal an entry logged at [hour] most likely belongs to.
  ///
  /// A guess, and only ever a starting point for the form: whoever is typing
  /// can say otherwise. It exists so the common case — writing down what you
  /// are eating right now — needs no answer at all.
  ///
  /// The small hours are dinner, not breakfast: something eaten at two in the
  /// morning belongs to the night that is ending.
  static Meal forHour(int hour) => switch (hour) {
    >= 5 && < 11 => Meal.breakfast,
    >= 11 && < 16 => Meal.lunch,
    >= 16 && < 19 => Meal.snack,
    _ => Meal.dinner,
  };
}
