import 'package:drift/drift.dart';

/// A counter of consecutive repetitions, with its historical record.
@DataClassName('StreakRow')
class Streaks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get count => integer().withDefault(const Constant(0))();
  IntColumn get maxStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime()();
}

/// One point of a streak's evolution, appended on every increment.
@TableIndex(name: 'streak_history_lookup', columns: {#streakId, #reachedAt})
@DataClassName('StreakHistoryRow')
class StreakHistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get streakId =>
      integer().references(Streaks, #id, onDelete: KeyAction.cascade)();
  IntColumn get count => integer()();
  DateTimeColumn get reachedAt => dateTime()();
}
