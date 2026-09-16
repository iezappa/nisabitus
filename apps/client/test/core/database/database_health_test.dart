import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_health.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nisabitus_health_');
    file = File('${dir.path}/store.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// What IndexedDB left behind in the incident recorded in TODO.md: every
  /// table and index on disk, and a `user_version` that never got written, so
  /// the next launch believes the store is brand new and creates it again.
  Future<void> leaveHalfCreated() async {
    final first = AppDatabase.forTesting(NativeDatabase(file));
    await first.customSelect('SELECT 1').get();
    await first
        .into(first.habits)
        .insert(
          HabitsCompanion.insert(
            name: 'Meditar',
            frequency: 'DAILY',
            status: 'PENDING',
            createdAt: DateTime(2026, 3, 11),
            scheduledDate: DateTime(2026, 3, 11),
          ),
        );
    await first.customStatement('PRAGMA user_version = 0');
    await first.close();
  }

  group('a half-created store', () {
    test('opens, instead of failing to create what already exists', () async {
      await leaveHalfCreated();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);

      expect(await probeDatabase(db), isA<DatabaseHealthy>());
    });

    test('keeps the rows it already had', () async {
      await leaveHalfCreated();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);

      expect(await db.select(db.habits).get(), hasLength(1));
    });
  });

  group('probeDatabase', () {
    test('reports a store that opens as healthy', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(await probeDatabase(db), isA<DatabaseHealthy>());
    });

    test(
      'reports a store that cannot be opened, rather than throwing',
      () async {
        file.writeAsStringSync('this is not a sqlite database, not even close');

        final db = AppDatabase.forTesting(NativeDatabase(file));
        addTearDown(db.close);

        expect(await probeDatabase(db), isA<DatabaseUnopenable>());
      },
    );
  });
}
