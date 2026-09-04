import 'nutrition.dart';

/// The heaviest single portion the app will take, in grams.
///
/// Twenty kilos is not a meal, and a field with no ceiling is a field where a
/// slipped keystroke silently rewrites the day's totals. The limit is here
/// rather than in the widget because it is a fact about what an entry may
/// hold, not about how the form looks.
const maxPortionGrams = 20000.0;

/// What [grams] of a food quoted per 100 g adds up to.
///
/// The whole reason the database stores figures per 100 g: one reference
/// value, scaled to whatever was actually on the plate. Every entry is
/// `per100 * grams / 100`, worked out once, here.
///
/// The result is rounded rather than truncated. The entry's columns are whole
/// numbers, and truncating loses a fraction on nearly every entry — always
/// downwards, so a day of eating would add up to visibly less than it was.
/// Rounding is wrong by less and is wrong in both directions.
Macros scaleMacros(Macros per100g, double grams) {
  if (grams < 0) {
    throw ArgumentError.value(grams, 'grams', 'Must not be negative');
  }

  int at(int per100) => (per100 * grams / 100).round();

  return Macros(
    calories: at(per100g.calories),
    protein: at(per100g.protein),
    carbs: at(per100g.carbs),
    fat: at(per100g.fat),
  );
}

/// Reads the weight typed into the form, or null when there is no usable
/// number in it.
///
/// Null is not zero: a blank field is nobody having said what this weighs,
/// and an unanswered field must not scale a food down to nothing. The form
/// tells the two apart — blank leaves the figures alone, zero is a weight.
///
/// A comma is read as a decimal point, because that is how the number is
/// written in Spanish and a field that only understands `12.5` refuses the
/// way the user was taught to write it.
double? parseGrams(String text) {
  final raw = text.trim().replaceAll(',', '.');
  if (raw.isEmpty) return null;

  final parsed = double.tryParse(raw);
  if (parsed == null || parsed < 0 || parsed > maxPortionGrams) return null;

  return parsed;
}
