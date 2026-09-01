import '../../../core/time/date_range.dart';
import 'medication.dart';
import 'medication_stats.dart';

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

  /// Records a new entry, started on [today] — the app's idea of today
  /// rather than each layer's own reading of the clock.
  Future<Medication> create(MedicationDraft draft, {DateTime? today});

  /// Edits an entry. An entry brought back from paused starts again on
  /// [today]: what it did before the pause is not this regimen.
  Future<Medication> update(int id, MedicationDraft draft, {DateTime? today});

  Future<void> delete(int id);

  /// Flips whether [id] was taken on [day].
  Future<bool> toggleIntake(int id, DateTime day);

  /// The figures the progress view shows for [range].
  Future<MedicationStats> statsFor(DateRange range);
}
