import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/dashboard/domain/activity_grid.dart';

void main() {
  // A Monday, so a week of the grid is a week of the calendar.
  final monday = DateTime(2026, 9, 7);
  final sunday = DateTime(2026, 9, 27);

  ActivityGrid gridOf(Map<DateTime, int> counts, {DateTime? from}) =>
      ActivityGrid.from(
        DateRange(from ?? monday, sunday),
        counts,
        firstWeekday: DateTime.monday,
      );

  group('a day', () {
    test('is empty when nothing was recorded', () {
      final day = ActivityDay(day: _never, count: 0);

      expect(day.isEmpty, isTrue);
      expect(day.level, 0);
    });

    test('darkens as more piles up, and stops darkening at the top', () {
      int levelOf(int count) => ActivityDay(day: _never, count: count).level;

      expect([levelOf(1), levelOf(2)], everyElement(1));
      expect([levelOf(3), levelOf(5)], everyElement(2));
      expect([levelOf(6), levelOf(9)], everyElement(3));
      expect([levelOf(10), levelOf(400)], everyElement(4));
    });

    test('means the same thing whatever else the window holds', () {
      // The point of fixed thresholds: one enormous day does not dim every
      // other day of the grid.
      final quiet = gridOf({monday: 2});
      final loud = gridOf({monday: 2, monday.add(const Duration(days: 1)): 90});

      int levelAt(ActivityGrid grid, DateTime day) => grid.weeks
          .expand((week) => week)
          .firstWhere((square) => square.day == day)
          .level;

      expect(levelAt(quiet, monday), levelAt(loud, monday));
    });
  });

  group('the grid', () {
    test('holds whole weeks, so a row is always one weekday', () {
      final grid = gridOf(const {});

      expect(grid.weeks, hasLength(3));
      expect(grid.weeks, everyElement(hasLength(7)));
      for (final week in grid.weeks) {
        expect(week.first.day.weekday, DateTime.monday);
      }
    });

    test('opens on the Monday before a window that starts mid-week', () {
      // Wednesday the 9th: the column still starts on the 7th, with the two
      // days before the window drawn empty rather than the row shifted up.
      final grid = gridOf(const {}, from: DateTime(2026, 9, 9));

      expect(grid.weeks.first.first.day, monday);
    });

    test('adds up what was recorded', () {
      final grid = gridOf({
        monday: 3,
        monday.add(const Duration(days: 1)): 1,
        monday.add(const Duration(days: 9)): 4,
      });

      expect(grid.total, 8);
      expect(grid.activeDays, 3);
      expect(grid.isEmpty, isFalse);
    });

    test('is empty when the window is', () {
      final grid = gridOf(const {});

      expect(grid.total, 0);
      expect(grid.activeDays, 0);
      expect(grid.isEmpty, isTrue);
    });

    test('ignores days outside the window', () {
      final grid = gridOf({sunday.add(const Duration(days: 3)): 5});

      expect(grid.total, 0);
    });

    test('counts the longest run across week boundaries', () {
      // Saturday through Tuesday: four days over two columns.
      final grid = gridOf({
        for (var i = 5; i <= 8; i++) monday.add(Duration(days: i)): 1,
        monday: 1,
      });

      expect(grid.longestRun(sunday), 4);
    });

    test('does not let a day that has not arrived break a run', () {
      final today = monday.add(const Duration(days: 2));
      final grid = gridOf({
        for (var i = 0; i <= 2; i++) monday.add(Duration(days: i)): 1,
      });

      expect(grid.longestRun(today), 3);
    });
  });
}

/// A date for the cases that are about the count and not the day.
final _never = DateTime(2026);
