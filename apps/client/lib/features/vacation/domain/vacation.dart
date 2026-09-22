import '../../../core/time/date_range.dart';

/// What the user is asking for when they write a break down.
class VacationDraft {
  VacationDraft({required DateTime start, DateTime? end, String? note})
    : start = dateOnly(start),
      end = end == null ? null : dateOnly(end),
      note = validateVacationNote(note) {
    final until = this.end;
    if (until != null && until.isBefore(this.start)) {
      throw ArgumentError.value(
        end,
        'end',
        'A break cannot end before it starts',
      );
    }
  }

  final DateTime start;

  /// Null while the break is still going. See [VacationPeriod.isOpenEnded].
  final DateTime? end;

  final String? note;

  static const maxNoteLength = 255;
}

/// Trims a break's note, and treats a blank one as no note at all.
String? validateVacationNote(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (trimmed.length > VacationDraft.maxNoteLength) {
    throw ArgumentError.value(value, 'note', 'The note is too long');
  }
  return trimmed;
}

/// A stretch of days that does not count against the user.
class VacationPeriod {
  VacationPeriod({
    required this.id,
    required DateTime start,
    DateTime? end,
    String? note,
  }) : start = dateOnly(start),
       endsOn = end == null ? null : dateOnly(end),
       note = validateVacationNote(note) {
    final until = endsOn;
    if (until != null && until.isBefore(this.start)) {
      throw ArgumentError.value(
        end,
        'end',
        'A break cannot end before it starts',
      );
    }
  }

  VacationPeriod.of(String id, VacationDraft draft)
    : this(id: id, start: draft.start, end: draft.end, note: draft.note);

  final String id;
  final DateTime start;

  /// The day the break ends, or null while it is still going.
  final DateTime? endsOn;

  final String? note;

  /// Whether the break is still going: turned on, not yet turned off.
  bool get isOpenEnded => endsOn == null;

  /// Whether [day] falls inside the break.
  ///
  /// An open-ended break covers every day from its start onwards, including
  /// days still to come: the user is away until they say otherwise.
  bool covers(DateTime day) {
    final at = dateOnly(day);
    if (at.isBefore(start)) return false;

    final until = endsOn;
    return until == null || !at.isAfter(until);
  }

  /// How long the break ran, in whole days, up to and including [today].
  ///
  /// An open-ended break is counted as far as today and no further: it has
  /// not lasted into next week yet.
  int lengthBy(DateTime today) {
    final last = endsOn ?? dateOnly(today);
    if (last.isBefore(start)) return 0;

    return last.difference(start).inDays + 1;
  }

  VacationPeriod endedOn(DateTime day) =>
      VacationPeriod(id: id, start: start, end: day, note: note);
}

/// Every break the user has written down, asked about one day at a time.
///
/// Held as a value rather than queried per day: the streak rule below asks
/// about every day of a gap, and the habits screen asks about the day it is
/// showing, so the answer has to be cheap.
class VacationCalendar {
  const VacationCalendar(this.periods);

  /// Nothing is paused. The default everywhere, so a caller that knows
  /// nothing about breaks behaves exactly as it did before they existed.
  static const none = VacationCalendar(<VacationPeriod>[]);

  final List<VacationPeriod> periods;

  bool get isEmpty => periods.isEmpty;

  /// Whether [day] is paused.
  bool covers(DateTime day) => periods.any((period) => period.covers(day));

  /// The break [day] falls in, if it falls in one.
  VacationPeriod? periodOn(DateTime day) {
    for (final period in periods) {
      if (period.covers(day)) return period;
    }
    return null;
  }

  /// The break that is still going, if the user is away.
  VacationPeriod? get openPeriod {
    for (final period in periods) {
      if (period.isOpenEnded) return period;
    }
    return null;
  }

  /// How many days of [range] were paused.
  int pausedDaysIn(DateRange range) => range.days.where(covers).length;

  /// Whether every day strictly between [after] and [before] was paused.
  ///
  /// This is the question a streak asks: the run survives a gap only if the
  /// user had said they were away for all of it. An empty gap — consecutive
  /// days — is vacuously all paused, and the caller has nothing to forgive.
  bool everyDayPausedBetween(DateTime after, DateTime before) {
    var day = dateOnly(after);
    final last = dateOnly(before);

    while (true) {
      day = DateTime(day.year, day.month, day.day + 1);
      if (!day.isBefore(last)) return true;
      if (!covers(day)) return false;
    }
  }
}
