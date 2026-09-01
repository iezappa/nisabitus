// Migration tests run against the schema snapshots in `drift_schemas/`, which
// are dumped from the code as it stood at each version. Adding a version means
// bumping `schemaVersion`, writing the step in `AppDatabase.migration`, and
// then:
//
//   dart run drift_dev schema dump lib/core/database/app_database.dart \
//     drift_schemas/
//   dart run drift_dev schema generate --data-classes --companions \
//     drift_schemas/ test/core/database/generated/
//
// Everything else here is a real database being upgraded the way an installed
// copy would be, which is the only place a broken step can be caught before a
// user meets it.
// drift exports an `isNull` expression builder that collides with the matcher.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v4.dart' as v4;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  // An installed copy can be any age: someone who has not opened the app since
  // v1 upgrades through every step at once. One test per version, so a failure
  // names the step that broke rather than the loop.
  for (final version in GeneratedHelper.versions) {
    test('reaches the current schema from v$version', () async {
      final schema = await verifier.schemaAt(version);
      final db = AppDatabase.forTesting(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, GeneratedHelper.versions.last);
    });
  }

  test('leaves the medications already stored with no start date', () async {
    // Null means "for as long as the record goes back". Stamping the day of
    // the migration would read as a regimen begun the morning the user
    // updated, and turn every earlier day into one it was missed on.
    final schema = await verifier.schemaAt(4);

    final before = v4.DatabaseAtV4(schema.newConnection());
    await before
        .into(before.medications)
        .insert(
          v4.MedicationsCompanion.insert(
            name: 'Vitamina D',
            kind: 'SUPPLEMENT',
            dose: const Value('1000 UI'),
          ),
        );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);

    final stored = await db.select(db.medications).getSingle();
    expect(stored.name, 'Vitamina D');
    expect(stored.dose, '1000 UI');
    expect(stored.activeFrom, isNull);
  });

  test('carries the unique intake index up from before it existed', () async {
    // The index is what makes ticking a medication a toggle rather than a
    // counter. A database that reached v5 through the migration rather than
    // through `onCreate` has to have it too, or the same thing could be
    // ticked twice on one day.
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);

    final id = await db
        .into(db.medications)
        .insert(
          MedicationsCompanion.insert(name: 'Vitamina D', kind: 'SUPPLEMENT'),
        );
    final day = DateTime(2026, 3, 11);
    await db
        .into(db.medicationIntakes)
        .insert(MedicationIntakesCompanion.insert(medicationId: id, date: day));

    expect(
      db
          .into(db.medicationIntakes)
          .insert(
            MedicationIntakesCompanion.insert(medicationId: id, date: day),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('keeps foreign keys enforced after an upgrade', () async {
    // The pragma is set per connection in `beforeOpen`, and a migration opens
    // the database on its own terms. A cascade that stops cascading would
    // leave orphaned rows behind every delete.
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);

    expect(
      db
          .into(db.habitCompletions)
          .insert(
            HabitCompletionsCompanion.insert(
              habitId: 999,
              completionDate: DateTime(2026, 3, 11),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
