import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';

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
    );
  }

  @override
  Future<Medication> create(MedicationDraft draft) async {
    final validated = _fromDraft(draft, id: 0);

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
          ),
        );

    return (await _byId(id))!;
  }

  @override
  Future<Medication> update(int id, MedicationDraft draft) async {
    final validated = _fromDraft(draft, id: id);

    await (_db.update(_db.medications)..where((m) => m.id.equals(id))).write(
      MedicationsCompanion(
        name: Value(validated.name),
        kind: Value(validated.kind.wireName),
        dose: Value(validated.dose),
        schedule: Value(validated.schedule),
        notes: Value(validated.notes),
        active: Value(validated.active),
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
    final removed =
        await (_db.delete(_db.medicationIntakes)..where(
              (i) => i.medicationId.equals(id) & i.date.equals(date),
            ))
            .go();

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

  Medication _toDomain(MedicationRow row) => Medication(
    id: row.id,
    name: row.name,
    kind: MedicationKind.parse(row.kind),
    dose: row.dose,
    schedule: row.schedule,
    notes: row.notes,
    active: row.active,
  );
}
