// A migration that is interrupted has to be survivable.
//
// drift writes `user_version` only after the whole `onUpgrade` callback
// returns, so a process killed halfway through leaves a store whose recorded
// version is the one it started at and whose tables are already partly in the
// new shape. The next launch replays the upgrade from the beginning. Every
// step it re-runs has to be a no-op on the work it already did, or the store
// never opens again — and a store that never opens is every record the user
// ever wrote, on a device with no account to restore from.
//
// These tests build exactly that state by hand: a dump at an old version with
// one later step already applied, `user_version` untouched.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  /// Opens [schema] raw, at [version], to do to it what a half-finished
  /// upgrade would have done.
  Future<void> interrupt(
    InitializedSchema schema,
    int version,
    List<String> statements,
  ) async {
    final raw = _RawDatabase(schema.newConnection(), version);
    for (final statement in statements) {
      await raw.customStatement(statement);
    }
    await raw.close();
  }

  test('finishes an upgrade that was killed after the v4 column', () async {
    final schema = await verifier.schemaAt(3);

    final before = _RawDatabase(schema.newConnection(), 3);
    await before.customStatement(
      "INSERT INTO projects (id, name) VALUES (1, 'Casa')",
    );
    await before.customStatement(
      "INSERT INTO todo_tasks (id, title, priority, status, project_id) "
      "VALUES (1, 'Sobrevivir', 'HIGH', 'TODO', 1)",
    );
    await before.close();

    // The upgrade started, added v4's column, and the process died before
    // drift could record that anything had happened.
    await interrupt(schema, 3, [
      'ALTER TABLE todo_tasks ADD COLUMN completed_at INTEGER NULL',
    ]);

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final task = await db.select(db.todoTasks).getSingle();
    expect(task.title, 'Sobrevivir');
    expect(task.completedAt, null);
  });

  test('finishes an upgrade that was killed after the v6 column', () async {
    final schema = await verifier.schemaAt(5);

    final before = _RawDatabase(schema.newConnection(), 5);
    await before.customStatement(
      "INSERT INTO food_entries (id, name, calories, date) "
      "VALUES (1, 'Milanesa', 500, 1700000000)",
    );
    await before.close();

    await interrupt(schema, 5, [
      'ALTER TABLE food_entries ADD COLUMN meal TEXT NULL',
    ]);

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    expect((await db.select(db.foodEntries).getSingle()).name, 'Milanesa');
  });

  test('finishes an upgrade that was killed after the v9 column', () async {
    final schema = await verifier.schemaAt(8);

    final before = _RawDatabase(schema.newConnection(), 8);
    await before.customStatement(
      "INSERT INTO exercises (id, name) VALUES (1, 'Sentadilla')",
    );
    await before.close();

    await interrupt(schema, 8, [
      'ALTER TABLE exercises ADD COLUMN video_url TEXT NULL',
    ]);

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    expect((await db.select(db.exercises).getSingle()).name, 'Sentadilla');
  });

  test('finishes an upgrade that was killed after the v5 column', () async {
    final schema = await verifier.schemaAt(4);

    final before = _RawDatabase(schema.newConnection(), 4);
    await before.customStatement(
      "INSERT INTO medications (id, name, kind, active) "
      "VALUES (1, 'Vitamina D', 'SUPPLEMENT', 1)",
    );
    await before.close();

    await interrupt(schema, 4, [
      'ALTER TABLE medications ADD COLUMN active_from INTEGER NULL',
    ]);

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    expect((await db.select(db.medications).getSingle()).name, 'Vitamina D');
  });
  test('finishes an upgrade that was killed after the v21 rename', () async {
    // The rename went through and the column that follows it did not. The
    // replay finds no `focus_sounds` to rename and must not fall over the
    // table it already made.
    final schema = await verifier.schemaAt(20);

    await interrupt(schema, 20, [
      'ALTER TABLE focus_sounds RENAME TO audio_tracks',
    ]);

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    expect(await db.select(db.audioTracks).get(), isEmpty);
  });

  test('finishes an upgrade that was killed after the v22 column', () async {
    final schema = await verifier.schemaAt(21);

    final before = _RawDatabase(schema.newConnection(), 21);
    await before.customStatement(
      "INSERT INTO projects (id, updated_at, name) "
      "VALUES ('p', 0, 'Casa')",
    );
    await before.customStatement(
      "INSERT INTO board_columns (id, updated_at, project_id, name, position) "
      "VALUES ('c', 0, 'p', 'Pendiente', 0)",
    );
    await before.customStatement(
      "INSERT INTO todo_tasks "
      "(id, updated_at, title, priority, column_id, project_id) "
      "VALUES ('t', 0, 'Sobrevivir', 'HIGH', 'c', 'p')",
    );
    await before.close();

    await interrupt(schema, 21, [
      'ALTER TABLE todo_tasks ADD COLUMN owner TEXT NULL',
    ]);

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final task = await db.select(db.todoTasks).getSingle();
    expect(task.title, 'Sobrevivir');
    expect(task.owner, null);
  });
}

class _RawDatabase extends GeneratedDatabase {
  _RawDatabase(super.executor, this.schemaVersion);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  final int schemaVersion;
}
