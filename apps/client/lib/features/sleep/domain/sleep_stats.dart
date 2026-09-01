import 'dart:math' as math;

import '../../../core/time/daily_series.dart';
import '../../../core/time/date_range.dart';
import 'sleep_log.dart';

/// What the sleep history says over a window.
class SleepStats {
  const SleepStats._({
    required this.count,
    required this.average,
    required this.minHours,
    required this.maxHours,
    required this.optimalPercent,
    required this.consistency,
    required this.latest,
    required this.logs,
    required this.perDay,
  });

  /// Reads the figures off the nights of [range], in any order.
  factory SleepStats.from(DateRange range, List<SleepLog> logs) {
    if (logs.isEmpty) {
      return SleepStats._(
        count: 0,
        average: 0,
        minHours: null,
        maxHours: null,
        optimalPercent: 0,
        consistency: 0,
        latest: null,
        logs: const [],
        perDay: dailySeries(range, const {}),
      );
    }

    final ordered = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final hours = ordered.map((log) => log.hours).toList();
    final average = hours.reduce((a, b) => a + b) / hours.length;
    final optimal = ordered
        .where((log) => log.quality == SleepQuality.optimal)
        .length;

    // Standard deviation: how far a typical night sits from the average.
    // Lower means a more regular sleep pattern.
    final variance =
        hours
            .map((value) => math.pow(value - average, 2).toDouble())
            .reduce((a, b) => a + b) /
        hours.length;

    return SleepStats._(
      count: ordered.length,
      average: average,
      minHours: hours.reduce(math.min),
      maxHours: hours.reduce(math.max),
      optimalPercent: (optimal / ordered.length * 100).round(),
      consistency: math.sqrt(variance),
      latest: ordered.last,
      logs: ordered,
      perDay: dailySeries(range, {
        for (final log in ordered) log.date: log.hours,
      }),
    );
  }

  final int count;
  final double average;
  final double? minHours;
  final double? maxHours;

  /// Share of nights that landed in the seven to nine band.
  final int optimalPercent;

  /// Spread around the average. Zero means every night was identical.
  final double consistency;

  final SleepLog? latest;

  /// The nights themselves, ascending by date.
  final List<SleepLog> logs;

  /// Hours slept per night, one point for every day of the window.
  ///
  /// A night with no record reads as zero, the same reading every other
  /// module gives an unlogged day. It is not a claim that nothing was slept:
  /// [count] says how many nights were actually written down.
  final List<DailyPoint> perDay;

  bool get isEmpty => count == 0;
}
