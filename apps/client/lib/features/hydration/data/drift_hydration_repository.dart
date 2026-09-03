import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/hydration.dart';
import '../domain/hydration_repository.dart';
import '../domain/hydration_stats.dart';

/// Drift-backed implementation of [HydrationRepository].
class DriftHydrationRepository implements HydrationRepository {
  DriftHydrationRepository(this._db);

  final AppDatabase _db;

  /// The target lives in a single pinned row.
  static const _goalId = 1;

  @override
  Future<HydrationGoal> goal() async {
    final row = await (_db.select(
      _db.hydrationGoals,
    )..where((g) => g.id.equals(_goalId))).getSingleOrNull();

    if (row == null) return HydrationGoal.fallback;

    return HydrationGoal(millilitres: row.millilitres);
  }

  @override
  Future<HydrationGoal> saveGoal(HydrationGoal goal) async {
    await _db
        .into(_db.hydrationGoals)
        .insertOnConflictUpdate(
          HydrationGoalsCompanion.insert(
            id: const Value(_goalId),
            millilitres: Value(goal.millilitres),
          ),
        );

    return goal;
  }

  @override
  Future<List<WaterEntry>> entriesFor(DateTime day) async {
    final rows =
        await (_db.select(_db.waterEntries)
              ..where((e) => e.date.equals(dateOnly(day)))
              ..orderBy([(e) => OrderingTerm.asc(e.id)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<DailyHydration> dayFor(DateTime day) async {
    final (entries, target) = await (entriesFor(day), goal()).wait;

    return DailyHydration.from(entries, target);
  }

  @override
  Future<WaterEntry> addEntry(DateTime day, int millilitres) async {
    final date = dateOnly(day);
    // Building the entity first lets the domain reject an impossible drink
    // before anything is written.
    final validated = WaterEntry(id: 0, date: date, millilitres: millilitres);

    final id = await _db
        .into(_db.waterEntries)
        .insert(
          WaterEntriesCompanion.insert(
            date: date,
            millilitres: validated.millilitres,
          ),
        );

    return validated.copyWith(id: id);
  }

  @override
  Future<void> deleteEntry(int id) async {
    await (_db.delete(_db.waterEntries)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<HydrationStats> statsFor(DateRange range) async {
    final rows = await (_db.select(
      _db.waterEntries,
    )..where((e) => e.date.isBetweenValues(range.start, range.end))).get();

    final (entries, target) = (rows.map(_toDomain).toList(), await goal());

    return HydrationStats.from(range, entries, target);
  }

  WaterEntry _toDomain(WaterEntryRow row) =>
      WaterEntry(id: row.id, date: row.date, millilitres: row.millilitres);
}
