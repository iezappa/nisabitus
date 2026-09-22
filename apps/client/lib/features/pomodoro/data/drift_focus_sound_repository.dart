import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/database/uuid.dart';
import '../domain/focus_sound.dart';
import '../domain/focus_sound_repository.dart';

/// Drift-backed implementation of [FocusSoundRepository].
class DriftFocusSoundRepository implements FocusSoundRepository {
  DriftFocusSoundRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<FocusSound>> list() async {
    // In the order they were added, which is the order the user built the
    // list in — alphabetical would reshuffle it under them every time they
    // renamed one.
    final rows = await (_db.select(
      _db.focusSounds,
    )..orderBy([(s) => OrderingTerm.asc(s.rowId)])).get();

    return [
      for (final row in rows)
        FocusSound(id: row.id, name: row.name, url: row.url),
    ];
  }

  @override
  Future<FocusSound> add(FocusSoundDraft draft) async {
    final id = newUuid();
    await _db
        .into(_db.focusSounds)
        .insert(
          FocusSoundsCompanion.insert(
            id: Value(id),
            name: draft.name,
            url: draft.url,
          ),
        );

    return FocusSound(id: id, name: draft.name, url: draft.url);
  }

  @override
  Future<FocusSound> update(String id, FocusSoundDraft draft) async {
    await (_db.update(
      _db.focusSounds,
    )..where((s) => s.id.equals(id))).writeTouched(
      FocusSoundsCompanion(name: Value(draft.name), url: Value(draft.url)),
    );

    return FocusSound(id: id, name: draft.name, url: draft.url);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.focusSounds)..where((s) => s.id.equals(id))).go();
  }
}
