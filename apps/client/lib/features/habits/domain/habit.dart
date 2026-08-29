import '../../../core/time/date_range.dart';
import 'habit_frequency.dart';

/// Where a habit stands for the period being looked at.
enum HabitStatus {
  pending('PENDING'),
  done('DONE'),
  cancelled('CANCELLED');

  const HabitStatus(this.wireName);

  final String wireName;

  /// Parses a stored or user-supplied value.
  ///
  /// `COMPLETED` is accepted as an alias of [HabitStatus.done] for
  /// compatibility with data written by earlier versions. A null or blank
  /// value falls back to [HabitStatus.pending].
  static HabitStatus parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return HabitStatus.pending;
    if (normalized == 'COMPLETED') return HabitStatus.done;

    for (final status in HabitStatus.values) {
      if (status.wireName == normalized) return status;
    }
    throw ArgumentError.value(value, 'value', 'Unknown habit status');
  }
}

/// A day of the week, used to restrict when a habit is expected.
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

/// A habit the user intends to repeat over time.
///
/// [completed] is not stored: it is resolved when listing a given day, by
/// looking for a completion inside the period the frequency defines.
class Habit {
  Habit({
    required this.id,
    required String name,
    required this.frequency,
    required this.status,
    required this.createdAt,
    required this.scheduledDate,
    this.description,
    this.category,
    this.targetCount = 1,
    DateTime? endDate,
    this.repeatForever = false,
    this.repeatDays = const {},
    this.type,
    this.completed = false,
  }) : name = _validateName(name),
       // Repeating forever and having an end date are mutually exclusive;
       // the flag wins so the two can never disagree.
       endDate = repeatForever || endDate == null ? null : dateOnly(endDate) {
    if (targetCount < 0 || targetCount > 10000) {
      throw ArgumentError.value(
        targetCount,
        'targetCount',
        'The target must be between 0 and 10000',
      );
    }
  }

  final int id;
  final String name;
  final String? description;
  final String? category;
  final HabitFrequency frequency;
  final int targetCount;
  final DateTime? endDate;
  final bool repeatForever;
  final Set<Weekday> repeatDays;
  final String? type;
  final HabitStatus status;
  final DateTime createdAt;
  final DateTime scheduledDate;

  /// Resolved per day rather than stored. See [Habit] docs.
  final bool completed;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  /// Whether [day] falls past the habit's end date.
  bool isFinishedOn(DateTime day) {
    final end = endDate;
    return end != null && dateOnly(day).isAfter(end);
  }

  /// Whether the habit is expected on [day].
  ///
  /// Weekday restrictions only apply to daily and weekly habits; monthly and
  /// yearly ones are expected on any day of their period.
  bool isScheduledOn(DateTime day) {
    if (isFinishedOn(day)) return false;
    if (!frequency.supportsRepeatDays || repeatDays.isEmpty) return true;
    return repeatDays.contains(Weekday.of(day));
  }

  /// Whether the list should show the "Nx" badge on [day].
  bool showsTargetBadge(DateTime day) =>
      targetCount > 1 && isScheduledOn(day);

  Habit copyWith({
    String? name,
    Object? description = _unset,
    Object? category = _unset,
    HabitFrequency? frequency,
    int? targetCount,
    Object? endDate = _unset,
    bool? repeatForever,
    Set<Weekday>? repeatDays,
    Object? type = _unset,
    HabitStatus? status,
    DateTime? scheduledDate,
    bool? completed,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    description: description == _unset
        ? this.description
        : description as String?,
    category: category == _unset ? this.category : category as String?,
    frequency: frequency ?? this.frequency,
    targetCount: targetCount ?? this.targetCount,
    endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
    repeatForever: repeatForever ?? this.repeatForever,
    repeatDays: repeatDays ?? this.repeatDays,
    type: type == _unset ? this.type : type as String?,
    status: status ?? this.status,
    createdAt: createdAt,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    completed: completed ?? this.completed,
  );

  static const _unset = Object();
}
