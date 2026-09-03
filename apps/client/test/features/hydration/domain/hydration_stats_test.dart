import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/hydration/domain/hydration.dart';
import 'package:nisabitus/features/hydration/domain/hydration_stats.dart';

void main() {
  final monday = DateTime(2026, 3, 9);
  final week = DateRange(monday, monday.add(const Duration(days: 6)));
  final goal = HydrationGoal(millilitres: 2000);

  WaterEntry drink(int ml, DateTime day, {int id = 1}) =>
      WaterEntry(id: id, date: day, millilitres: ml);

  test('is empty before anything was drunk', () {
    final stats = HydrationStats.from(week, const [], goal);

    expect(stats.isEmpty, isTrue);
    expect(stats.average, 0);
  });

  test('adds the drinks of a day together', () {
    final stats = HydrationStats.from(week, [
      drink(500, monday, id: 1),
      drink(750, monday, id: 2),
    ], goal);

    expect(stats.total, 1250);
    expect(stats.daysLogged, 1);
  });

  test('averages over the days logged, not over the window', () {
    // A day with no record is silence. Dividing by seven would report a
    // thirst nobody suffered.
    final stats = HydrationStats.from(week, [
      drink(2000, monday, id: 1),
      drink(1000, monday.add(const Duration(days: 1)), id: 2),
    ], goal);

    expect(stats.average, 1500);
  });

  test('counts the days that reached the target', () {
    final stats = HydrationStats.from(week, [
      drink(2000, monday, id: 1),
      drink(500, monday.add(const Duration(days: 1)), id: 2),
    ], goal);

    expect(stats.daysOnTarget, 1);
  });

  test('counts no day as on target when there is no target', () {
    final stats = HydrationStats.from(week, [
      drink(2000, monday),
    ], HydrationGoal(millilitres: 0));

    expect(stats.daysOnTarget, 0);
  });

  test('drops what falls outside the window it was asked about', () {
    final stats = HydrationStats.from(week, [
      drink(2000, monday, id: 1),
      drink(3000, monday.subtract(const Duration(days: 1)), id: 2),
    ], goal);

    expect(stats.total, 2000);
  });

  test(
    'gives every day of the window a point, zero where nothing was drunk',
    () {
      final stats = HydrationStats.from(week, [drink(2000, monday)], goal);

      expect(stats.perDay, hasLength(7));
      expect(stats.perDay.first.value, 2000);
      expect(stats.perDay.last.value, 0);
    },
  );
}
