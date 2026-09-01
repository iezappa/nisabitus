import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';
import '../domain/medication_stats.dart';

/// Drift-backed implementation of [MedicationRepository].
class DriftMedicationRepository implements MedicationRepository {
  DriftMedicationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Medication>> all() async {
    final rows =
        await (_db.select(_db.medications)..orderBy([
              // Active first, then alphabetical: what is paused is history.
              (m) => OrderingTerm.desc(m.active),
              (m) => OrderingTerm.asc(m.name),
            ]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<MedicationDay> dayFor(DateTime day) async {
    final medications = await all();
    final rows = await (_db.select(
      _db.medicationIntakes,
    )..where((i) => i.date.equals(dateOnly(day)))).get();

    return MedicationDay.from(
      medications,
      rows.map((row) => row.medicationId).toSet(),
      day: dateOnly(day),
    );
  }

  @override
  Future<Medication> create(MedicationDraft draft, {DateTime? today}) async {
    final validated = _fromDraft(draft, id: 0);
    final start = dateOnly(today ?? DateTime.now());

    final id = await _db
        .into(_db.medications)
        .insert(
          MedicationsCompanion.insert(
            name: validated.name,
            kind: validated.kind.wireName,
            dose: Value(validated.dose),
            schedule: Value(validated.schedule),
            notes: Value(validated.notes),
            active: Value(validated.active),
            activeFrom: Value(start),
          ),
        );

    return (await _byId(id))!;
  }

  @override
  Future<Medication> update(
    int id,
    MedicationDraft draft, {
    DateTime? today,
  }) async {
    final validated = _fromDraft(draft, id: id);
    final current = await _byId(id);

    // Coming back from paused starts a new run: the days it sat inactive
    // were never missed, and counting them would be adherence for a regimen
    // nobody was on. Editing an entry that never stopped leaves it alone.
    final resumed = validated.active && current != null && !current.active;

    await (_db.update(_db.medications)..where((m) => m.id.equals(id))).write(
      MedicationsCompanion(
        name: Value(validated.name),
        kind: Value(validated.kind.wireName),
        dose: Value(validated.dose),
        schedule: Value(validated.schedule),
        notes: Value(validated.notes),
        active: Value(validated.active),
        activeFrom: resumed
            ? Value(dateOnly(today ?? DateTime.now()))
            : const Value.absent(),
      ),
    );

    return (await _byId(id))!;
  }

  @override
  Future<void> delete(int id) async {
    // The cascade in the schema takes every day it was ticked on.
    await (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();
  }

  @override
  Future<bool> toggleIntake(int id, DateTime day) async {
    final date = dateOnly(day);
    final removed = await (_db.delete(
      _db.medicationIntakes,
    )..where((i) => i.medicationId.equals(id) & i.date.equals(date))).go();

    if (removed > 0) return false;

    await _db
        .into(_db.medicationIntakes)
        .insert(
          MedicationIntakesCompanion.insert(medicationId: id, date: date),
        );

    return true;
  }

  Future<Medication?> _byId(int id) async {
    final row = await (_db.select(
      _db.medications,
    )..where((m) => m.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  Medication _fromDraft(MedicationDraft draft, {required int id}) => Medication(
    id: id,
    name: draft.name,
    kind: draft.kind,
    dose: draft.dose,
    schedule: draft.schedule,
    notes: draft.notes,
    active: draft.active,
  );

  @override
  Future<MedicationStats> statsFor(DateRange range) async {
    // Only what is active counts, on both sides of the sum: a paused entry
    // is history, so neither its ticks nor its absences are adherence.
    final active = await (_db.select(
      _db.medications,
    )..where((m) => m.active.equals(true))).get();

    if (active.isEmpty) {
      return MedicationStats.from(
        range,
        activeFrom: const [],
        intakeDays: const [],
      );
    }

    final activeIds = active.map((m) => m.id).toList();
    final intakes =
        await (_db.select(_db.medicationIntakes)..where(
              (i) =>
                  i.date.isBetweenValues(range.start, range.end) &
                  i.medicationId.isIn(activeIds),
            ))
            .get();

    return MedicationStats.from(
      range,
      activeFrom: active.map((row) => row.activeFrom).toList(),
      intakeDays: intakes.map((row) => row.date).toList(),
    );
  }

  Medication _toDomain(MedicationRow row) => Medication(
    id: row.id,
    name: row.name,
    kind: MedicationKind.parse(row.kind),
    dose: row.dose,
    schedule: row.schedule,
    notes: row.notes,
    active: row.active,
    activeFrom: row.activeFrom,
  );
}
