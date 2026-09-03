import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/meditation/domain/meditation.dart';
import 'package:nisabitus/features/meditation/domain/meditation_stats.dart';

void main() {
  final monday = DateTime(2026, 3, 9);
  final week = DateRange(monday, monday.add(const Duration(days: 6)));

  MeditationSession sat(int minutes, DateTime day, {int id = 1}) =>
      MeditationSession(id: id, date: day, minutes: minutes);

  DateTime dayOf(int offset) => monday.add(Duration(days: offset));

  test('is empty before anything was sat', () {
    final stats = MeditationStats.from(week, const []);

    expect(stats.isEmpty, isTrue);
    expect(stats.averageMinutes, 0);
    expect(stats.longestStreak, 0);
  });

  test('adds the sittings of a day together', () {
    final stats = MeditationStats.from(week, [
      sat(10, monday, id: 1),
      sat(15, monday, id: 2),
    ]);

    expect(stats.totalMinutes, 25);
    expect(stats.sessionCount, 2);
    expect(stats.daysPractised, 1);
  });

  test('averages over the days practised, not over the window', () {
    // A day nothing was written on is silence. Dividing by seven would
    // report a practice falling apart when it was only unrecorded.
    final stats = MeditationStats.from(week, [
      sat(20, monday, id: 1),
      sat(10, dayOf(1), id: 2),
    ]);

    expect(stats.averageMinutes, 15);
  });

  test('counts the longest run of consecutive days', () {
    final stats = MeditationStats.from(week, [
      sat(10, monday, id: 1),
      sat(10, dayOf(1), id: 2),
      sat(10, dayOf(2), id: 3),
      // A day off here.
      sat(10, dayOf(4), id: 4),
    ]);

    expect(stats.longestStreak, 3);
  });

  test('breaks the run on a day nothing was sat', () {
    final stats = MeditationStats.from(week, [
      sat(10, monday, id: 1),
      sat(10, dayOf(2), id: 2),
    ]);

    expect(stats.longestStreak, 1);
  });

  test('drops what falls outside the window it was asked about', () {
    final stats = MeditationStats.from(week, [
      sat(20, monday, id: 1),
      sat(60, monday.subtract(const Duration(days: 1)), id: 2),
    ]);

    expect(stats.totalMinutes, 20);
    expect(stats.sessionCount, 1);
  });

  test('gives every day of the window a point, zero where nothing was sat', () {
    final stats = MeditationStats.from(week, [sat(20, monday)]);

    expect(stats.perDay, hasLength(7));
    expect(stats.perDay.first.value, 20);
    expect(stats.perDay.last.value, 0);
  });
}
