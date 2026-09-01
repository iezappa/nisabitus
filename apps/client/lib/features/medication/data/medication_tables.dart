import 'package:drift/drift.dart';

/// Something the user takes, described once and ticked off many times.
@DataClassName('MedicationRow')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Stored as the canonical wire name of MedicationKind.
  TextColumn get kind => text().withLength(max: 16)();

  /// Free text, so "500 mg", "2 cápsulas" and "10 gotas" all fit.
  TextColumn get dose => text().withLength(max: 255).nullable()();

  /// Free text too: the app never interprets a schedule, it only shows it.
  TextColumn get schedule => text().withLength(max: 255).nullable()();

  TextColumn get notes => text().withLength(max: 5000).nullable()();

  /// Paused entries stay in the list but leave the day alone.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// The day the entry started counting, so a window that reaches back
  /// before a new prescription does not read it as a run of missed days.
  ///
  /// Null for rows written before the column existed: their start is
  /// genuinely unknown, and treating it as today would rewrite history.
  DateTimeColumn get activeFrom => dateTime().nullable()();
}

/// A record that something was taken on a given day.
///
/// One row per medication per day, so ticking is a toggle rather than a
/// counter the user has to keep straight.
@DataClassName('MedicationIntakeRow')
@TableIndex(
  name: 'intake_by_day',
  columns: {#date, #medicationId},
  unique: true,
)
class MedicationIntakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
}
