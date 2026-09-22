import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// A focus session made of alternating focus and break phases.
@DataClassName('PomodoroSessionRow')
class PomodoroSessions extends Table with RecordColumns {
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

/// A sound the user plays while focusing: rain, white noise, a long track.
///
/// A library of its own rather than a field on the session, because what you
/// listen to and what you are working on are not the same choice: the same
/// rain recording serves every session, and a session repeated tomorrow
/// should not drag last week's soundtrack along with it.
///
/// The link is stored exactly as pasted and read at the point of use, so a
/// row can never be a URL this build would not have accepted.
@DataClassName('FocusSoundRow')
class FocusSounds extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get url => text().withLength(min: 1, max: 2000)();
}
