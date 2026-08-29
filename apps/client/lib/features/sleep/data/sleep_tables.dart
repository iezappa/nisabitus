import 'package:drift/drift.dart';

/// How many hours were slept on a given night.
///
/// At most one record per day: registering the same day again updates the
/// existing row.
class SleepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Hours slept, in half-hour steps between 0 and 24.
  RealColumn get hours => real()();
  DateTimeColumn get date => dateTime().unique()();
}
