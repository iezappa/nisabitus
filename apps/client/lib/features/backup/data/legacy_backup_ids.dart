import '../../../core/database/app_database.dart';
import '../../../core/database/uuid.dart';
import '../domain/backup_document.dart';

/// Which table each reference field of a backup row points at.
///
/// Keyed by table and JSON field, which is the Dart name drift serialises.
const _references = {
  'habit_completions': {'habitId': 'habits'},
  'streak_history_entries': {'streakId': 'streaks'},
  'projects': {'parentId': 'projects'},
  'todo_tasks': {'projectId': 'projects'},
  'task_comments': {'taskId': 'todo_tasks'},
  'scheduled_exercises': {'exerciseId': 'exercises'},
  'medication_intakes': {'medicationId': 'medications'},
};

/// Where a row's first `updatedAt` comes from, when it carries one.
const _lastWritten = {
  'habits': 'createdAt',
  'task_comments': 'createdAt',
  'streaks': 'lastUpdated',
};

const _singletonTables = {'nutrition_goals', 'hydration_goals', 'step_goals'};

/// Rewrites a format 1 backup — integer ids — into the format 2 shape.
///
/// Every row gets a fresh UUID, drawn once per `(table, old id)`, and every
/// reference is looked up in the same map, so a completion still belongs to
/// its habit and a subproject still hangs from its parent. The same integer
/// in two tables is two different records, and gets two different UUIDs.
///
/// A reference to an id the file does not hold is left as the old number in
/// text form. It points nowhere, the foreign key rejects it, and the whole
/// restore rolls back: a broken file is refused, never half-restored.
///
/// `updatedAt` starts from the row's own creation time where it has one, and
/// from the moment the file was exported otherwise.
///
/// A document already in the current format is returned untouched.
BackupDocument upgradeLegacyIds(BackupDocument document) {
  if (document.format >= 2) return document;

  final ids = <String, Map<Object?, String>>{
    for (final MapEntry(key: table, value: rows) in document.tables.entries)
      table: {
        for (final row in rows)
          row['id']: _singletonTables.contains(table)
              ? AppDatabase.singletonId
              : newUuid(),
      },
  };

  String? translate(String table, Object? old) {
    if (old == null) return null;
    return ids[table]?[old] ?? '$old';
  }

  final exported = document.exportedAt.millisecondsSinceEpoch;

  return BackupDocument(
    schemaVersion: document.schemaVersion,
    exportedAt: document.exportedAt,
    tables: {
      for (final MapEntry(key: table, value: rows) in document.tables.entries)
        table: [
          for (final row in rows)
            {
              ...row,
              'id': translate(table, row['id']),
              for (final MapEntry(key: field, value: parent)
                  in (_references[table] ?? const <String, String>{}).entries)
                field: translate(parent, row[field]),
              'updatedAt':
                  row['updatedAt'] ?? row[_lastWritten[table]] ?? exported,
            },
        ],
    },
  );
}
