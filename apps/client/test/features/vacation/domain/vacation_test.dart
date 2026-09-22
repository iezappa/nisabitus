import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/vacation/domain/vacation.dart';

void main() {
  final monday = DateTime(2026, 9, 7);
  final friday = DateTime(2026, 9, 11);

  VacationPeriod period(DateTime start, [DateTime? end]) =>
      VacationPeriod(id: 'v', start: start, end: end);

  group('a break', () {
    test('covers its own days, and nothing either side', () {
      final away = period(monday, friday);

      expect(away.covers(monday), isTrue);
      expect(away.covers(DateTime(2026, 9, 9)), isTrue);
      expect(away.covers(friday), isTrue);
      expect(away.covers(DateTime(2026, 9, 6)), isFalse);
      expect(away.covers(DateTime(2026, 9, 12)), isFalse);
    });

    test('covers the time of day too, not just midnight', () {
      expect(period(monday, friday).covers(DateTime(2026, 9, 9, 22, 30)), true);
    });

    test('runs on with no end until the user says otherwise', () {
      final away = period(monday);

      expect(away.isOpenEnded, isTrue);
      expect(away.covers(DateTime(2027, 1, 1)), isTrue);
      expect(away.covers(DateTime(2026, 9, 6)), isFalse);
    });

    test('lasts one day when it starts and ends on the same one', () {
      expect(period(monday, monday).lengthBy(friday), 1);
    });

    test('is counted as far as today while it is still going', () {
      // Not into next week: the days after today have not been away yet.
      expect(period(monday).lengthBy(friday), 5);
    });

    test('refuses to end before it began', () {
      expect(
        () => VacationPeriod(id: 'v', start: friday, end: monday),
        throwsArgumentError,
      );
    });

    test('treats a blank note as no note', () {
      expect(VacationPeriod(id: 'v', start: monday, note: '   ').note, isNull);
    });
  });

  group('the calendar', () {
    test('pauses nothing when the user has taken no breaks', () {
      expect(VacationCalendar.none.covers(monday), isFalse);
      expect(VacationCalendar.none.isEmpty, isTrue);
    });

    test('answers for any of the breaks written down', () {
      final calendar = VacationCalendar([
        period(monday, DateTime(2026, 9, 8)),
        period(DateTime(2026, 9, 20), DateTime(2026, 9, 25)),
      ]);

      expect(calendar.covers(monday), isTrue);
      expect(calendar.covers(DateTime(2026, 9, 22)), isTrue);
      expect(calendar.covers(DateTime(2026, 9, 15)), isFalse);
    });

    test('names the break that is still open', () {
      final closed = period(monday, friday);
      final open = VacationPeriod(id: 'open', start: DateTime(2026, 9, 20));
      final calendar = VacationCalendar([closed, open]);

      expect(calendar.openPeriod?.id, 'open');
      expect(VacationCalendar([closed]).openPeriod, isNull);
    });

    test('counts how many days of a window were paused', () {
      final calendar = VacationCalendar([period(monday, DateTime(2026, 9, 9))]);

      expect(calendar.pausedDaysIn(DateRange(monday, friday)), 3);
    });
  });

  group('a gap', () {
    // The question a streak asks before deciding a run is broken.
    test('is forgiven when every day of it was paused', () {
      final calendar = VacationCalendar([
        period(DateTime(2026, 9, 8), DateTime(2026, 9, 10)),
      ]);

      expect(
        calendar.everyDayPausedBetween(monday, DateTime(2026, 9, 11)),
        true,
      );
    });

    test('is not forgiven when one day of it was not', () {
      final calendar = VacationCalendar([
        period(DateTime(2026, 9, 8), DateTime(2026, 9, 9)),
      ]);

      // The 10th was a normal day, and nothing was recorded on it.
      expect(
        calendar.everyDayPausedBetween(monday, DateTime(2026, 9, 11)),
        isFalse,
      );
    });

    test('with no days in it asks nothing of the calendar', () {
      // Consecutive days: there is no gap to forgive, paused or not.
      expect(
        VacationCalendar.none.everyDayPausedBetween(
          monday,
          DateTime(2026, 9, 8),
        ),
        isTrue,
      );
    });
  });
}
