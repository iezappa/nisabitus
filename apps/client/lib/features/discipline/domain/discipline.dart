import '../../../core/time/date_range.dart';
import '../../../core/time/weekday.dart';

/// Something practised for a time rather than counted in sets.
///
/// Swimming, running, cycling. Deliberately not an [Exercise]: a swim is not
/// four sets of ten at eighty kilos, it is forty minutes and two kilometres,
/// and a table with both shapes in it is two tables wearing one name — half
/// its columns null on every row.
///
/// The rest of it works exactly like a scheduled exercise: one row per day,
/// which is both the plan and the record, and a repetition is written down as
/// its own days rather than kept as a rule to be interpreted later.
class Discipline {
  Discipline({
    required this.id,
    required String name,
    required DateTime scheduledDate,
    required this.durationMinutes,
    this.distanceKm,
    String? notes,
    String? feedback,
    this.completed = false,
    this.recurrenceGroupId,
    this.repeatDays = const {},
    this.repeatForever = false,
  }) : name = _validateName(name),
       scheduledDate = dateOnly(scheduledDate),
       notes = _clean(notes),
       feedback = _clean(feedback) {
    if (durationMinutes < 1 || durationMinutes > maxMinutes) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'Must be between 1 and $maxMinutes',
      );
    }
    if (distanceKm != null &&
        (distanceKm! <= 0 || distanceKm! > maxDistanceKm)) {
      throw ArgumentError.value(
        distanceKm,
        'distanceKm',
        'Must be between 0 and $maxDistanceKm',
      );
    }
  }

  /// Twelve hours. Past that it is not a session, it is a typo.
  static const maxMinutes = 720;

  /// A thousand kilometres in one go is not a session either.
  static const maxDistanceKm = 1000.0;

  final int id;

  /// Free text, so the user's own vocabulary works. There is no catalogue
  /// behind this: what is practised is written as it is called.
  final String name;

  final DateTime scheduledDate;
  final int durationMinutes;

  /// Null when the session is not measured in distance — a yoga class has a
  /// duration and no kilometres, and zero would claim it was measured.
  final double? distanceKm;

  /// Written when planning.
  final String? notes;

  /// How it went, written afterwards.
  final String? feedback;

  final bool completed;

  final String? recurrenceGroupId;
  final Set<Weekday> repeatDays;
  final bool repeatForever;

  bool get isRecurring =>
      recurrenceGroupId != null && recurrenceGroupId!.isNotEmpty;

  Discipline copyWith({
    int? id,
    DateTime? scheduledDate,
    bool? completed,
    String? recurrenceGroupId,
    bool? repeatForever,
  }) => Discipline(
    id: id ?? this.id,
    name: name,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    durationMinutes: durationMinutes,
    distanceKm: distanceKm,
    notes: notes,
    feedback: feedback,
    completed: completed ?? this.completed,
    recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
    repeatDays: repeatDays,
    repeatForever: repeatForever ?? this.repeatForever,
  );

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
