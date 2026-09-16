import 'package:drift/wasm.dart';

import 'app_database.dart';

/// Removes the browser database, whichever storage drift had put it in.
Future<void> eraseLocalStore() async {
  final probe = await WasmDatabase.probe(
    sqlite3Uri: AppDatabase.sqlite3WasmUri,
    driftWorkerUri: AppDatabase.driftWorkerUri,
    databaseName: AppDatabase.storeName,
  );

  for (final existing in probe.existingDatabases) {
    if (existing.$2 == AppDatabase.storeName) {
      await probe.deleteDatabase(existing);
    }
  }
}
