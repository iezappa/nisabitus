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

/// Forces the store open and reports how that went, without throwing.
///
/// A trivial query is enough: drift runs the whole open — the file, the
/// migrations, `beforeOpen` — before it answers anything.
Future<DatabaseHealth> probeDatabase(AppDatabase db) async {
  try {
    await db.customSelect('SELECT 1').get();
    return const DatabaseHealthy();
  } on Object catch (error) {
    return DatabaseUnopenable(error);
  }
}
