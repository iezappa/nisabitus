import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/database/uuid.dart';
import '../../../core/time/date_range.dart';
import '../domain/vacation.dart';
import '../domain/vacation_repository.dart';

/// Drift-backed implementation of [VacationRepository].
class DriftVacationRepository implements VacationRepository {
  DriftVacationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<VacationPeriod>> list() async {
    final rows = await (_db.select(
      _db.vacationPeriods,
    )..orderBy([(v) => OrderingTerm.asc(v.startDate)])).get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<VacationCalendar> calendar() async => VacationCalendar(await list());

  @override
  Future<VacationPeriod> add(VacationDraft draft) async {
    final id = newUuid();
    await _db
        .into(_db.vacationPeriods)
        .insert(
          VacationPeriodsCompanion.insert(
            id: Value(id),
            startDate: draft.start,
            endDate: Value(draft.end),
            note: Value(draft.note),
          ),
        );

    return VacationPeriod.of(id, draft);
  }

  @override
  Future<VacationPeriod> update(String id, VacationDraft draft) async {
    await (_db.update(
      _db.vacationPeriods,
    )..where((v) => v.id.equals(id))).writeTouched(
      VacationPeriodsCompanion(
        startDate: Value(draft.start),
        endDate: Value(draft.end),
        note: Value(draft.note),
      ),
    );

    return VacationPeriod.of(id, draft);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.vacationPeriods)..where((v) => v.id.equals(id))).go();
  }

  @override
  Future<VacationPeriod> start(DateTime day) async {
    // The one already running wins. Turning the switch on while a break is
    // open would otherwise file a second one that says the same thing, and
    // turning it off would then close only one of them.
    final open = (await calendar()).openPeriod;
    if (open != null) return open;

    return add(VacationDraft(start: day));
  }

  @override
  Future<void> end(DateTime day) async {
    final open = (await calendar()).openPeriod;
    if (open == null) return;

    final last = dateOnly(day);
    await update(
      open.id,
      VacationDraft(
        start: open.start,
        // A break that has not started yet is closed on the day it began, so
        // it lasts the one day it was on rather than ending before it.
        end: last.isBefore(open.start) ? open.start : last,
        note: open.note,
      ),
    );
  }

  VacationPeriod _toDomain(VacationPeriodRow row) => VacationPeriod(
    id: row.id,
    start: row.startDate,
    end: row.endDate,
    note: row.note,
  );
}
