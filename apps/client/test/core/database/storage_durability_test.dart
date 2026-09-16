import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/storage_durability.dart';

void main() {
  group('durabilityOf', () {
    test('trusts the origin private file system', () {
      expect(
        durabilityOf(WasmStorageImplementation.opfsShared),
        StorageDurability.durable,
      );
      expect(
        durabilityOf(WasmStorageImplementation.opfsLocks),
        StorageDurability.durable,
      );
    });

    test('calls IndexedDB degraded, since it persists lazily', () {
      expect(
        durabilityOf(WasmStorageImplementation.sharedIndexedDb),
        StorageDurability.degraded,
      );
      expect(
        durabilityOf(WasmStorageImplementation.unsafeIndexedDb),
        StorageDurability.degraded,
      );
    });

    test('calls memory volatile, since nothing survives a reload', () {
      expect(
        durabilityOf(WasmStorageImplementation.inMemory),
        StorageDurability.volatile,
      );
    });
  });
}
