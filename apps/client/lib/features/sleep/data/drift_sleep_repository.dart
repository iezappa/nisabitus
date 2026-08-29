import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/sleep_log.dart';
import '../domain/sleep_repository.dart';
import '../domain/sleep_stats.dart';

/// Drift-backed implementation of [SleepRepository].
class DriftSleepRepository implements SleepRepository {
  DriftSleepRepository(this._db);

  final AppDatabase _db;

  @override
  Future<SleepLog?> forDay(DateTime day) async {
    final row = await (_db.select(
      _db.sleepLogs,
    )..where((s) => s.date.equals(dateOnly(day)))).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<SleepLog> save(DateTime day, double hours) async {
    final date = dateOnly(day);
    // Building the entity first lets the domain reject impossible hours
    // before anything is written.
    final validated = SleepLog(id: 0, hours: hours, date: date);

    // The unique index on the date is what makes this an update rather than
    // a second row for the same night.
    await _db
        .into(_db.sleepLogs)
        .insert(
          SleepLogsCompanion.insert(hours: validated.hours, date: date),
          onConflict: DoUpdate(
            (_) => SleepLogsCompanion(hours: Value(validated.hours)),
            target: [_db.sleepLogs.date],
          ),
        );

    return (await forDay(date))!;
  }

  @override
  Future<List<SleepLog>> inRange(DateRange range) async {
    final rows =
        await (_db.select(_db.sleepLogs)
              ..where((s) => s.date.isBetweenValues(range.start, range.end))
              ..orderBy([(s) => OrderingTerm.asc(s.date)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<SleepStats> statsFor(DateRange range) async =>
      SleepStats.from(await inRange(range));

  SleepLog _toDomain(SleepLogRow row) =>
      SleepLog(id: row.id, hours: row.hours, date: row.date);
}
