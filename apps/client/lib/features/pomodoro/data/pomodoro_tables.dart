import 'package:drift/drift.dart';

/// A focus session made of alternating focus and break phases.
@DataClassName('PomodoroSessionRow')
class PomodoroSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get category => text().withLength(max: 255).nullable()();
  TextColumn get purpose => text().withLength(max: 5000).nullable()();

  /// Planned number of focus cycles.
  IntColumn get cycles => integer().withDefault(const Constant(4))();
  IntColumn get focusDuration => integer().withDefault(const Constant(25))();
  IntColumn get breakDuration => integer().withDefault(const Constant(5))();
  IntColumn get completedCycles => integer().withDefault(const Constant(0))();

  /// Stored as the canonical wire name of PomodoroStatus.
  TextColumn get status => text().withLength(max: 16)();
  DateTimeColumn get startedAt => dateTime()();
}
