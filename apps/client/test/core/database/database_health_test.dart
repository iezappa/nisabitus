import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_health.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'generated/schema.dart';

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

  Future<void> leaveCurrentStoreMissingUpdatedAt() async {
    final raw = sqlite.sqlite3.open(file.path);
    raw
      ..execute('''
        CREATE TABLE habits (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NULL,
          category TEXT NULL,
          frequency TEXT NOT NULL,
          target_count INTEGER NOT NULL DEFAULT 1,
          end_date INTEGER NULL,
          repeat_forever INTEGER NOT NULL DEFAULT 0,
          repeat_days TEXT NOT NULL DEFAULT '',
          type TEXT NULL,
          status TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          scheduled_date INTEGER NOT NULL
        )
      ''')
      ..execute(
        'INSERT INTO habits '
        '(id, name, frequency, status, created_at, scheduled_date) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['habit-1', 'Meditar', 'DAILY', 'PENDING', 0, 0],
      )
      ..execute('PRAGMA user_version = ${AppDatabase.currentSchemaVersion}');
    raw.close();
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

  group('a current-version store missing updatedAt', () {
    test('repairs the column before generated writes reach SQLite', () async {
      await leaveCurrentStoreMissingUpdatedAt();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);

      expect(await probeDatabase(db), isA<DatabaseHealthy>());
      await db
          .into(db.habits)
          .insert(
            HabitsCompanion.insert(
              name: 'Leer',
              frequency: 'DAILY',
              status: 'PENDING',
              createdAt: DateTime(2026, 3, 12),
              scheduledDate: DateTime(2026, 3, 12),
            ),
          );

      expect(await db.select(db.habits).get(), hasLength(2));
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

  group('a store an older version of the app already holds open', () {
    // On the web every tab shares one drift worker, and the first tab to
    // connect opens the store. A tab still running the previous release keeps
    // it open at the old schema; a tab with this release then connects to
    // that same open store and drift, seeing it already open, never runs the
    // upgrade. Every write then fails on a column the old schema lacks.
    Future<AppDatabase> joinStoreOpenedAtV13() async {
      final schema = await SchemaVerifier(GeneratedHelper()).schemaAt(13);
      final connection = schema.newConnection();
      await _OlderRelease(connection).customSelect('SELECT 1').get();

      final db = AppDatabase.forTesting(connection.executor);
      addTearDown(db.close);
      return db;
    }

    test('is reported as held by an older version, not healthy', () async {
      final db = await joinStoreOpenedAtV13();

      final health = await probeDatabase(db);

      expect(health, isA<DatabaseHeldByOlderVersion>());
      expect((health as DatabaseHeldByOlderVersion).foundVersion, 13);
    });
  });
}

class _OlderRelease extends GeneratedDatabase {
  _OlderRelease(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 13;
}
