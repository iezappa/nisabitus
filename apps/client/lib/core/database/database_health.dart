import 'app_database.dart';

/// Whether the local store could be opened at all.
///
/// Drift opens lazily and remembers a failed migration: once opening throws,
/// every later query on that connection throws the same error. Every screen
/// reads from the database, so without a check up front one bad store takes
/// the whole app down at once, with nothing on screen to act on.
sealed class DatabaseHealth {
  const DatabaseHealth();
}

final class DatabaseHealthy extends DatabaseHealth {
  const DatabaseHealthy();
}

/// Opening, or migrating on the way in, threw.
final class DatabaseUnopenable extends DatabaseHealth {
  const DatabaseUnopenable(this.error);

  /// For the log, not for the user.
  final Object error;
}

/// The store is open, but at a schema older than this build's.
///
/// On the web every tab shares one drift worker, and whichever tab connects
/// first opens the store. A tab still running the previous release keeps it
/// open at the old schema; this build then joins that open store, and drift,
/// finding it already open, never runs the upgrade. Reads fail on columns
/// that are not there and every write is refused. Nothing is lost: the store
/// upgrades as soon as the old tab is closed and this one reloads.
final class DatabaseHeldByOlderVersion extends DatabaseHealth {
  const DatabaseHeldByOlderVersion(this.foundVersion);

  final int foundVersion;
}

/// Forces the store open and reports how that went, without throwing.
///
/// Any query is enough to open it: drift runs the whole open — the file, the
/// migrations, `beforeOpen` — before it answers anything.
Future<DatabaseHealth> probeDatabase(AppDatabase db) async {
  try {
    final version = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((row) => row.read<int>('user_version'));
    if (version < db.schemaVersion) return DatabaseHeldByOlderVersion(version);
    return const DatabaseHealthy();
  } on Object catch (error) {
    return DatabaseUnopenable(error);
  }
}
