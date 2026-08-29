import 'medication.dart';

/// The user-editable fields of a medication or supplement.
class MedicationDraft {
  const MedicationDraft({
    required this.name,
    this.kind = MedicationKind.fallback,
    this.dose,
    this.schedule,
    this.notes,
    this.active = true,
  });

  final String name;
  final MedicationKind kind;
  final String? dose;
  final String? schedule;
  final String? notes;
  final bool active;
}

/// The port the medication module talks to.
abstract interface class MedicationRepository {
  /// Everything the user has recorded, active or not.
  Future<List<Medication>> all();

  /// What is due on [day], with whether each one is ticked.
  Future<MedicationDay> dayFor(DateTime day);

  Future<Medication> create(MedicationDraft draft);

  Future<Medication> update(int id, MedicationDraft draft);

  Future<void> delete(int id);

  /// Flips whether [id] was taken on [day].
  Future<bool> toggleIntake(int id, DateTime day);
}
