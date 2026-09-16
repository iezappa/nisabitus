import 'package:drift_flutter/drift_flutter.dart';

/// How much the storage the database landed on can be trusted with.
///
/// Native platforms write a SQLite file and are always [durable]. The web
/// build takes whatever the browser allows, and drift says which it chose.
enum StorageDurability {
  /// Written to a real file: the origin private file system, or disk.
  durable,

  /// IndexedDB. It persists, but lazily: a reload or a browser clean-up at
  /// the wrong moment can lose recent writes, or leave the store half made.
  degraded,

  /// Memory only. Nothing survives closing the tab.
  volatile,
}

StorageDurability durabilityOf(WasmStorageImplementation implementation) =>
    switch (implementation) {
      WasmStorageImplementation.opfsShared ||
      WasmStorageImplementation.opfsLocks => StorageDurability.durable,
      WasmStorageImplementation.sharedIndexedDb ||
      WasmStorageImplementation.unsafeIndexedDb => StorageDurability.degraded,
      WasmStorageImplementation.inMemory => StorageDurability.volatile,
    };
