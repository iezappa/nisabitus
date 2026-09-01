import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/habits/domain/habit.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';

void main() {
  Habit habit({
    HabitFrequency frequency = HabitFrequency.daily,
    Set<Weekday> repeatDays = const {},
    DateTime? endDate,
    bool repeatForever = false,
    int targetCount = 1,
  }) => Habit(
    id: 1,
    name: 'Meditar',
    frequency: frequency,
    targetCount: targetCount,
    endDate: endDate,
    repeatForever: repeatForever,
    repeatDays: repeatDays,
    status: HabitStatus.pending,
    createdAt: DateTime(2026, 3, 1),
    scheduledDate: DateTime(2026, 3, 1),
  );

  group('HabitStatus.parse', () {
    test('accepts the canonical names', () {
      expect(HabitStatus.parse('PENDING'), HabitStatus.pending);
      expect(HabitStatus.parse('DONE'), HabitStatus.done);
      expect(HabitStatus.parse('CANCELLED'), HabitStatus.cancelled);
    });

    test('treats COMPLETED as an alias of DONE', () {
      expect(HabitStatus.parse('COMPLETED'), HabitStatus.done);
    });

    test('normalizes casing and whitespace', () {
      expect(HabitStatus.parse(' done '), HabitStatus.done);
    });

    test('falls back to pending when null or blank', () {
      expect(HabitStatus.parse(null), HabitStatus.pending);
      expect(HabitStatus.parse('  '), HabitStatus.pending);
    });

    test('rejects an unknown value', () {
      expect(() => HabitStatus.parse('SKIPPED'), throwsArgumentError);
    });
  });

  group('Weekday', () {
    test('maps a DateTime to its weekday', () {
      // 2026-03-09 is a Monday, 2026-03-15 a Sunday.
      expect(Weekday.of(DateTime(2026, 3, 9)), Weekday.monday);
      expect(Weekday.of(DateTime(2026, 3, 15)), Weekday.sunday);
    });

    test('parses the canonical names', () {
      expect(Weekday.parse('MONDAY'), Weekday.monday);
      expect(Weekday.parse('sunday'), Weekday.sunday);
    });

    test('round-trips through a stored list', () {
      const days = {Weekday.monday, Weekday.wednesday, Weekday.friday};

      expect(Weekday.decode(Weekday.encode(days)), days);
    });

    test('decodes an empty string as no restriction', () {
      expect(Weekday.decode(''), isEmpty);
      expect(Weekday.decode('   '), isEmpty);
    });

    test('ignores blank entries while decoding', () {
      expect(Weekday.decode('MONDAY,,FRIDAY'), {Weekday.monday, Weekday.friday});
    });
  });

  group('Habit.isFinishedOn', () {
    test('is false while the end date has not passed', () {
      final h = habit(endDate: DateTime(2026, 3, 15));

      expect(h.isFinishedOn(DateTime(2026, 3, 14)), isFalse);
      expect(h.isFinishedOn(DateTime(2026, 3, 15)), isFalse);
    });

    test('is true the day after the end date', () {
      final h = habit(endDate: DateTime(2026, 3, 15));

      expect(h.isFinishedOn(DateTime(2026, 3, 16)), isTrue);
    });

    test('is always false without an end date', () {
      expect(habit().isFinishedOn(DateTime(2030, 1, 1)), isFalse);
    });

    test('is always false when the habit repeats forever', () {
      final h = habit(repeatForever: true, endDate: DateTime(2026, 3, 15));

      expect(h.endDate, isNull, reason: 'repeating forever clears the end date');
      expect(h.isFinishedOn(DateTime(2030, 1, 1)), isFalse);
    });
  });

  group('Habit.isScheduledOn', () {
    test('is true every day when no weekdays are chosen', () {
      final h = habit();

      expect(h.isScheduledOn(DateTime(2026, 3, 11)), isTrue);
      expect(h.isScheduledOn(DateTime(2026, 3, 15)), isTrue);
    });

    test('honours the chosen weekdays', () {
      final h = habit(repeatDays: {Weekday.monday, Weekday.wednesday});

      expect(h.isScheduledOn(DateTime(2026, 3, 9)), isTrue);
      expect(h.isScheduledOn(DateTime(2026, 3, 11)), isTrue);
      expect(h.isScheduledOn(DateTime(2026, 3, 10)), isFalse);
    });

    test('ignores weekdays for monthly and yearly habits', () {
      final h = habit(
        frequency: HabitFrequency.monthly,
        repeatDays: {Weekday.monday},
      );

      expect(h.isScheduledOn(DateTime(2026, 3, 10)), isTrue);
    });

    test('is false once the habit is finished', () {
      final h = habit(endDate: DateTime(2026, 3, 15));

      expect(h.isScheduledOn(DateTime(2026, 3, 16)), isFalse);
    });
  });

  group('Habit validation', () {
    test('rejects a blank name', () {
      expect(
        () => Habit(
          id: 1,
          name: '  ',
          frequency: HabitFrequency.daily,
          status: HabitStatus.pending,
          createdAt: DateTime(2026, 3, 1),
          scheduledDate: DateTime(2026, 3, 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a target count outside 0..10000', () {
      expect(() => habit(targetCount: -1), throwsArgumentError);
      expect(() => habit(targetCount: 10001), throwsArgumentError);
    });

    test('accepts the bounds of the target count', () {
      expect(habit(targetCount: 0).targetCount, 0);
      expect(habit(targetCount: 10000).targetCount, 10000);
    });
  });

  group('Habit.showsTargetBadge', () {
    test('is true only when the target is above one and the day is scheduled', () {
      expect(habit(targetCount: 3).showsTargetBadge(DateTime(2026, 3, 11)), isTrue);
      expect(habit(targetCount: 1).showsTargetBadge(DateTime(2026, 3, 11)), isFalse);
      expect(
        habit(targetCount: 3, repeatDays: {Weekday.monday})
            .showsTargetBadge(DateTime(2026, 3, 10)),
        isFalse,
      );
    });
  });
}
