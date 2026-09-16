import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_health.dart';
import 'storage_durability.dart';

/// The single database instance the whole app shares.
///
/// Overridden in tests with an in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    // Reported once the browser build has chosen its storage, which is
    // whenever the first query opens the connection.
    onStorageChosen: (durability) {
      try {
        ref.read(storageDurabilityProvider.notifier).state = durability;
      } on StateError {
        // The scope was thrown away before the database finished opening.
      }
    },
  );
  ref.onDispose(db.close);
  return db;
});

/// What the store underneath the database can be trusted with.
///
/// Durable until told otherwise: native platforms never report, and a web
/// build that has not opened yet has nothing to warn about.
final storageDurabilityProvider = StateProvider<StorageDurability>(
  (ref) => StorageDurability.durable,
);

/// Whether the database opened, checked once per app start.
final databaseHealthProvider = FutureProvider<DatabaseHealth>(
  (ref) => probeDatabase(ref.watch(databaseProvider)),
);
