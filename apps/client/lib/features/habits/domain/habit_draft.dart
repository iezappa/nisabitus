import 'habit.dart';
import 'habit_frequency.dart';

/// The user-editable fields of a habit, as submitted by the form.
///
/// Keeping this separate from [Habit] means the domain never has to invent an
/// id or a creation date for a habit that does not exist yet.
class HabitDraft {
  const HabitDraft({
    required this.name,
    required this.frequency,
    this.description,
    this.category,
    this.targetCount = 1,
    this.endDate,
    this.repeatForever = false,
    this.repeatDays = const {},
    this.type,
  });

  final String name;
  final HabitFrequency frequency;
  final String? description;
  final String? category;
  final int targetCount;
  final DateTime? endDate;
  final bool repeatForever;
  final Set<Weekday> repeatDays;
  final String? type;
}
