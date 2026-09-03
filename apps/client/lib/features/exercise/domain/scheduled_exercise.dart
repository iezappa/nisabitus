import '../../../core/time/date_range.dart';
import '../../../core/time/weekday.dart';

/// How long a repetition runs.
enum RecurrenceType {
  /// A fixed number of weeks from the first day.
  weeks('WEEKS'),

  /// Up to a date the user picks.
  until('DATE'),

  /// No end the user has to think about.
  forever('FOREVER');

  const RecurrenceType(this.wireName);

  final String wireName;
}

/// A repetition, as the form collects it.
///
/// Only used while creating: once the days are written down, each of them is
/// its own row and this object is gone. Nothing reads a recurrence back to
/// decide what is due — the days themselves say so.
class ExerciseRecurrence {
  ExerciseRecurrence({
    required this.days,
    required this.type,
    this.weeks,
    DateTime? endDate,
  }) : endDate = endDate == null ? null : dateOnly(endDate) {
    if (days.isEmpty) {
      throw ArgumentError.value(days, 'days', 'Pick at least one day');
    }
    if (type == RecurrenceType.weeks &&
        (weeks == null || weeks! < 1 || weeks! > maxWeeks)) {
      throw ArgumentError.value(
        weeks,
        'weeks',
        'A repetition runs for between 1 and $maxWeeks weeks',
      );
    }
    if (type == RecurrenceType.until && endDate == null) {
      throw ArgumentError.value(
        endDate,
        'endDate',
        'A repetition that runs until a date needs the date',
      );
    }
  }

  /// A year. Past that, "forever" is the honest answer.
  static const maxWeeks = 52;

  /// Ten years of days.
  ///
  /// "Forever" still has to be written down as days, because a day is what
  /// the screen shows and what gets ticked. Ten years is far enough away that
  /// nobody meets the edge, and near enough that the rows stay a database
  /// rather than a landfill.
  static const foreverHorizonWeeks = 520;

  final Set<Weekday> days;
  final RecurrenceType type;
  final int? weeks;
  final DateTime? endDate;

  /// The last day this repetition reaches, counting from [start].
  DateTime lastDay(DateTime start) {
    final from = dateOnly(start);

    return switch (type) {
      RecurrenceType.weeks => from.add(Duration(days: weeks! * 7)),
      RecurrenceType.forever => from.add(
        const Duration(days: foreverHorizonWeeks * 7),
      ),
      RecurrenceType.until => endDate!,
    };
  }

  /// Every day after [start] that this repetition lands on.
  ///
  /// The first day is excluded because it is the row the user is creating;
  /// these are the copies of it.
  List<DateTime> daysAfter(DateTime start) {
    final from = dateOnly(start);
    final last = lastDay(from);
    if (last.isBefore(from)) {
      throw ArgumentError.value(
        last,
        'endDate',
        'A repetition cannot end before it starts',
      );
    }

    final result = <DateTime>[];
    for (
      var day = from.add(const Duration(days: 1));
      !day.isAfter(last);
      day = day.add(const Duration(days: 1))
    ) {
      if (days.contains(Weekday.of(day))) result.add(day);
    }

    return result;
  }
}

/// One exercise on one day: what to do, and what happened.
///
/// The same row is both. A repetition is written down as one of these per
/// day rather than kept as a plan to compare against, which is what makes
/// correcting tomorrow leave yesterday exactly as it was lived.
class ScheduledExercise {
  ScheduledExercise({
    required this.id,
    required this.exerciseId,
    required DateTime scheduledDate,
    required this.sets,
    required this.reps,
    this.weightKg,
    this.rpe,
    String? comments,
    String? feedback,
    this.completed = false,
    this.recurrenceGroupId,
    this.repeatDays = const {},
    this.repeatForever = false,
  }) : scheduledDate = dateOnly(scheduledDate),
       comments = _clean(comments),
       feedback = _clean(feedback) {
    if (sets < 1 || sets > 100) {
      throw ArgumentError.value(sets, 'sets', 'Must be between 1 and 100');
    }
    if (reps < 1 || reps > 1000) {
      throw ArgumentError.value(reps, 'reps', 'Must be between 1 and 1000');
    }
    if (weightKg != null && (weightKg! < 0 || weightKg! > maxWeightKg)) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Must be between 0 and $maxWeightKg',
      );
    }
    if (rpe != null && (rpe! < 1 || rpe! > 10)) {
      throw ArgumentError.value(rpe, 'rpe', 'Must be between 1 and 10');
    }
  }

  static const maxWeightKg = 1000.0;

  final int id;
  final int exerciseId;
  final DateTime scheduledDate;

  final int sets;
  final int reps;

  /// Null when the movement carries no external load, which is not zero.
  final double? weightKg;

  /// Rate of perceived exertion, 1 to 10. How hard it actually was, which no
  /// weight on its own can say.
  final int? rpe;

  /// Cues written when planning: depth, tempo, what to watch for.
  final String? comments;

  /// How it went, written afterwards.
  final String? feedback;

  final bool completed;

  /// Ties the copies of one repetition together, so the series can be
  /// stopped from a day forward without touching what came before.
  final String? recurrenceGroupId;

  /// The days the repetition lands on. Kept on the row so the screen can say
  /// what it is part of; nothing computes what is due from it.
  final Set<Weekday> repeatDays;

  final bool repeatForever;

  bool get isRecurring =>
      recurrenceGroupId != null && recurrenceGroupId!.isNotEmpty;

  ScheduledExercise copyWith({
    int? id,
    DateTime? scheduledDate,
    bool? completed,
    String? recurrenceGroupId,
    bool? repeatForever,
  }) => ScheduledExercise(
    id: id ?? this.id,
    exerciseId: exerciseId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    sets: sets,
    reps: reps,
    weightKg: weightKg,
    rpe: rpe,
    comments: comments,
    feedback: feedback,
    completed: completed ?? this.completed,
    recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
    repeatDays: repeatDays,
    repeatForever: repeatForever ?? this.repeatForever,
  );

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
