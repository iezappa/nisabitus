import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/weekday.dart';
import 'package:nisabitus/features/exercise/domain/scheduled_exercise.dart';

void main() {
  // A Monday, so the weekday arithmetic reads.
  final monday = DateTime(2026, 3, 9);

  group('ExerciseRecurrence', () {
    ExerciseRecurrence weekly({
      Set<Weekday> days = const {Weekday.monday, Weekday.wednesday},
      RecurrenceType type = RecurrenceType.weeks,
      int? weeks = 2,
      DateTime? endDate,
    }) => ExerciseRecurrence(
      days: days,
      type: type,
      weeks: weeks,
      endDate: endDate,
    );

    test('refuses a repetition on no day at all', () {
      expect(() => weekly(days: const {}), throwsArgumentError);
    });

    test('refuses a run of weeks nobody would plan', () {
      expect(() => weekly(weeks: 0), throwsArgumentError);
      expect(() => weekly(weeks: 53), throwsArgumentError);
    });

    test('refuses to run until a date it was not given', () {
      expect(
        () => weekly(type: RecurrenceType.until, weeks: null),
        throwsArgumentError,
      );
    });

    test('writes down every matching day after the first', () {
      // The first day is the row being created; these are its copies.
      final days = weekly().daysAfter(monday);

      expect(days, [
        DateTime(2026, 3, 11), // Wednesday
        DateTime(2026, 3, 16), // Monday
        DateTime(2026, 3, 18),
        DateTime(2026, 3, 23),
      ]);
    });

    test('stops on the date it was told to stop on', () {
      final days = weekly(
        type: RecurrenceType.until,
        weeks: null,
        endDate: DateTime(2026, 3, 16),
      ).daysAfter(monday);

      expect(days, [DateTime(2026, 3, 11), DateTime(2026, 3, 16)]);
    });

    test('turns forever into ten years of days', () {
      // "Forever" still has to be written down as days, because a day is
      // what gets ticked. Ten years is far enough that nobody meets the end.
      final days = weekly(
        days: const {Weekday.monday},
        type: RecurrenceType.forever,
        weeks: null,
      ).daysAfter(monday);

      expect(days.length, ExerciseRecurrence.foreverHorizonWeeks);
    });

    test('refuses to end before it starts', () {
      expect(
        () => weekly(
          type: RecurrenceType.until,
          weeks: null,
          endDate: monday.subtract(const Duration(days: 1)),
        ).daysAfter(monday),
        throwsArgumentError,
      );
    });
  });

  group('ScheduledExercise', () {
    ScheduledExercise scheduled({
      int sets = 4,
      int reps = 8,
      double? weight = 80,
      int? rpe = 8,
      String? comments,
      String? feedback,
    }) => ScheduledExercise(
      id: 1,
      exerciseId: 1,
      scheduledDate: monday,
      sets: sets,
      reps: reps,
      weightKg: weight,
      rpe: rpe,
      comments: comments,
      feedback: feedback,
    );

    test('keeps the day it was scheduled for, without its time', () {
      final row = ScheduledExercise(
        id: 1,
        exerciseId: 1,
        scheduledDate: DateTime(2026, 3, 9, 18, 30),
        sets: 4,
        reps: 8,
      );

      expect(row.scheduledDate, monday);
    });

    test('refuses targets nobody trains', () {
      expect(() => scheduled(sets: 0), throwsArgumentError);
      expect(() => scheduled(reps: 0), throwsArgumentError);
      expect(() => scheduled(weight: 1001), throwsArgumentError);
    });

    test('refuses an effort outside the scale', () {
      // RPE is one to ten. Eleven is a joke, not a measurement.
      expect(() => scheduled(rpe: 0), throwsArgumentError);
      expect(() => scheduled(rpe: 11), throwsArgumentError);
    });

    test('accepts no weight and no effort, which are not zeroes', () {
      final row = scheduled(weight: null, rpe: null);

      expect(row.weightKg, isNull);
      expect(row.rpe, isNull);
    });

    test('reads blank text as nothing written', () {
      final row = scheduled(comments: '   ', feedback: '  ');

      expect(row.comments, isNull);
      expect(row.feedback, isNull);
    });

    test('is only part of a series when it says which one', () {
      expect(scheduled().isRecurring, isFalse);
      expect(
        scheduled().copyWith(recurrenceGroupId: 'abc').isRecurring,
        isTrue,
      );
    });

    test('copies itself onto another day untouched', () {
      final copy = scheduled(comments: 'Bajar hasta paralelo')
          .copyWith(id: 0, scheduledDate: DateTime(2026, 3, 11));

      expect(copy.scheduledDate, DateTime(2026, 3, 11));
      expect(copy.sets, 4);
      expect(copy.comments, 'Bajar hasta paralelo');
      expect(copy.completed, isFalse);
    });
  });
}
