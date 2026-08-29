import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_medication_repository.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => DriftMedicationRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final medicationRevisionProvider = StateProvider<int>((ref) => 0);

/// What is due on the day the week strip points at.
final medicationDayProvider = FutureProvider<MedicationDay>((ref) {
  ref.watch(medicationRevisionProvider);

  return ref
      .watch(medicationRepositoryProvider)
      .dayFor(ref.watch(selectedDayProvider));
});

/// The whole list, paused entries included.
final medicationCatalogueProvider = FutureProvider<List<Medication>>((ref) {
  ref.watch(medicationRevisionProvider);

  return ref.watch(medicationRepositoryProvider).all();
});

/// Write operations, kept out of the widgets.
class MedicationActions {
  MedicationActions(this._ref);

  final Ref _ref;

  MedicationRepository get _repository =>
      _ref.read(medicationRepositoryProvider);

  Future<void> create(MedicationDraft draft) async {
    await _repository.create(draft);
    _invalidate();
  }

  Future<void> update(int id, MedicationDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _invalidate();
  }

  Future<void> toggle(int id) async {
    await _repository.toggleIntake(id, _ref.read(selectedDayProvider));
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(medicationRevisionProvider.notifier).update((v) => v + 1);
}

final medicationActionsProvider = Provider<MedicationActions>(
  MedicationActions.new,
);
