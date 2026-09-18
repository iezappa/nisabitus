// `nutrition_goals` and `hydration_goals` hold one row each from v14 on, under
// the fixed id `singleton`. Before v14 nothing in the schema said so: the id
// was an autoincrementing integer, and a store that ever wrote a second row —
// a repository bug, a restored backup, a half-finished write — has two.
//
// The v14 step maps every row of those tables to the same `singleton` id, so
// two rows are two rows with the same primary key. Unhandled, that fails the
// upgrade and the app never opens again over a difference the user cannot see
// and did not cause.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  /// A v13 store whose single-row tables hold more than one row.
  Future<AppDatabase> migratedFromDuplicatedV13() async {
    final schema = await verifier.schemaAt(13);
    final before = _RawDatabase(schema.newConnection());
    // Ascending ids: the highest is the row written last, which is the one
    // the app would have been reading and the one the user last set.
    await before.customStatement(
      "INSERT INTO nutrition_goals (id, calories, protein, carbs, fat) VALUES "
      "(1, 1800, 100, 200, 60), (2, 2200, 140, 230, 70)",
    );
    await before.customStatement(
      "INSERT INTO hydration_goals (id, millilitres) VALUES "
      "(1, 2000), (3, 2500)",
    );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 14);
    return db;
  }

  test('upgrades a store whose goal tables hold more than one row', () async {
    final db = await migratedFromDuplicatedV13();

    expect((await db.select(db.nutritionGoals).get()), hasLength(1));
    expect((await db.select(db.hydrationGoals).get()), hasLength(1));
  });

  test('keeps the goals the user set last and drops the rest', () async {
    final db = await migratedFromDuplicatedV13();

    final nutrition = await db.select(db.nutritionGoals).getSingle();
    expect(nutrition.id, AppDatabase.singletonId);
    expect(nutrition.calories, 2200);
    expect(nutrition.protein, 140);

    final hydration = await db.select(db.hydrationGoals).getSingle();
    expect(hydration.id, AppDatabase.singletonId);
    expect(hydration.millilitres, 2500);
  });
}

class _RawDatabase extends GeneratedDatabase {
  _RawDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 13;
}
