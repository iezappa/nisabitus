import 'dart:math' as math;

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
  });

  /// Reads the figures off a set of nights, in any order.
  factory SleepStats.from(List<SleepLog> logs) {
    if (logs.isEmpty) {
      return const SleepStats._(
        count: 0,
        average: 0,
        minHours: null,
        maxHours: null,
        optimalPercent: 0,
        consistency: 0,
        latest: null,
        logs: [],
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

  /// The nights themselves, ascending by date, for the chart.
  final List<SleepLog> logs;

  bool get isEmpty => count == 0;
}
