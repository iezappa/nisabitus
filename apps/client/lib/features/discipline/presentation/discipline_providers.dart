import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../exercise/domain/scheduled_exercise.dart';
import '../data/drift_discipline_repository.dart';
import '../domain/discipline.dart';
import '../domain/discipline_repository.dart';

final disciplineRepositoryProvider = Provider<DisciplineRepository>(
  (ref) => DriftDisciplineRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final disciplineRevisionProvider = StateProvider<int>((ref) => 0);

/// What is practised on the day the week strip points at.
final disciplinesForDayProvider = FutureProvider<List<Discipline>>((ref) {
  ref.watch(disciplineRevisionProvider);

  return ref
      .watch(disciplineRepositoryProvider)
      .forDay(ref.watch(selectedDayProvider));
});

/// Write operations, kept out of the widgets.
class DisciplineActions {
  DisciplineActions(this._ref);

  final Ref _ref;

  DisciplineRepository get _repository =>
      _ref.read(disciplineRepositoryProvider);

  Future<void> schedule(
    DisciplineDraft draft, {
    ExerciseRecurrence? recurrence,
  }) async {
    await _repository.schedule(
      _ref.read(selectedDayProvider),
      draft,
      recurrence: recurrence,
    );
    _invalidate();
  }

  Future<void> update(int id, DisciplineDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> complete(int id, DisciplineCompletion completion) async {
    await _repository.complete(id, completion);
    _invalidate();
  }

  Future<void> reopen(int id) async {
    await _repository.reopen(id);
    _invalidate();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _invalidate();
  }

  Future<void> stopRecurrence(int id) async {
    await _repository.stopRecurrence(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(disciplineRevisionProvider.notifier).update((v) => v + 1);
}

final disciplineActionsProvider = Provider<DisciplineActions>(
  DisciplineActions.new,
);
