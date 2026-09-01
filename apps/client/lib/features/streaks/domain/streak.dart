import '../../../core/time/date_range.dart';

/// A counter of consecutive repetitions, with its historical record.
///
/// Every transition returns a new instance, so callers can compare the result
/// against the previous value before persisting it.
class Streak {
  Streak({
    required this.id,
    required String name,
    required this.count,
    required this.maxStreak,
    required DateTime lastUpdated,
  }) : name = _validateName(name),
       lastUpdated = dateOnly(lastUpdated);

  /// A brand new streak, with both counters at zero.
  factory Streak.create({
    required int id,
    required String name,
    DateTime? createdAt,
  }) => Streak(
    id: id,
    name: name,
    count: 0,
    maxStreak: 0,
    lastUpdated: createdAt ?? DateTime.now(),
  );

  final int id;
  final String name;
  final int count;
  final int maxStreak;
  final DateTime lastUpdated;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  /// Adds one to the count, raising the record when the count passes it.
  ///
  /// A streak is a run of consecutive days, so a whole calendar day with
  /// nothing recorded breaks it: the next increment restarts the count at one
  /// instead of resuming where it left off. Several increments on the same day
  /// are still allowed, and so is one the day after the last.
  ///
  /// The record survives the break, and is rescued first in case the stored
  /// count had outrun it.
  ///
  /// Recording a day earlier than the last update is a correction, not a new
  /// day: it adds to the run but leaves [lastUpdated] where it was. Dragging
  /// the date backwards would turn the days already recorded after it into a
  /// gap, and break the very run the correction was meant to rescue.
  ///
  /// The caller is responsible for appending the matching history entry.
  Streak increment(DateTime on) {
    final day = dateOnly(on);
    final record = count > maxStreak ? count : maxStreak;
    final next = _brokenBy(day) ? 1 : count + 1;

    return _copyWith(
      count: next,
      maxStreak: next > record ? next : record,
      lastUpdated: day.isAfter(lastUpdated) ? day : lastUpdated,
    );
  }

  /// Whether at least one full day passed between [day] and the last update.
  ///
  /// A date earlier than the last update cannot break a run: it is a
  /// correction of the past, not a gap.
  bool _brokenBy(DateTime day) =>
      lastUpdated.isBefore(DateTime(day.year, day.month, day.day - 1));

  /// Sends the count back to zero, keeping the record earned so far.
  ///
  /// The record is rescued first in case the stored count had outrun it, which
  /// can happen with imported data. A reset produces no history entry.
  Streak reset(DateTime on) => _copyWith(
    count: 0,
    maxStreak: count > maxStreak ? count : maxStreak,
    lastUpdated: on,
  );

  Streak rename(String newName) => _copyWith(name: newName);

  Streak _copyWith({
    String? name,
    int? count,
    int? maxStreak,
    DateTime? lastUpdated,
  }) => Streak(
    id: id,
    name: name ?? this.name,
    count: count ?? this.count,
    maxStreak: maxStreak ?? this.maxStreak,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

/// One point of a streak's evolution, recorded on every increment.
///
/// This is the source of the progress chart, and it is never deleted.
class StreakHistoryEntry {
  const StreakHistoryEntry({
    required this.id,
    required this.streakId,
    required this.count,
    required this.reachedAt,
  });

  final int id;
  final int streakId;
  final int count;
  final DateTime reachedAt;
}
