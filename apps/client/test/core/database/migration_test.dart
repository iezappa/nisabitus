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
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v8.dart' as v8;

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
    await verifier.migrateAndValidate(db, 11);

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
    await verifier.migrateAndValidate(db, 11);

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

  test('leaves the food already logged with no meal', () async {
    // Null means nobody said. Calling every earlier entry lunch would put
    // food on the record at an hour it was not eaten, and the day it lands on
    // would read as one that was logged properly.
    final schema = await verifier.schemaAt(5);
    final day = DateTime(2026, 3, 11);

    final before = v5.DatabaseAtV5(schema.newConnection());
    await before
        .into(before.foodEntries)
        .insert(
          v5.FoodEntriesCompanion.insert(
            // The generated snapshot speaks the storage format, not the app's:
            // drift keeps a DateTime as unix seconds unless told otherwise.
            date: day.millisecondsSinceEpoch ~/ 1000,
            name: 'Avena',
            calories: const Value(300),
          ),
        );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);

    final stored = await db.select(db.foodEntries).getSingle();
    expect(stored.name, 'Avena');
    expect(stored.calories, 300);
    expect(stored.meal, isNull);
  });

  test(
    'carries the unique food name index up from before it existed',
    () async {
      // Same trap as the intake index: `createTable` writes the table and
      // nothing else. Without this index the catalogue files a second "Avena"
      // every time the casing changes, and the picker fills up with the same
      // food over and over.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase.forTesting(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 11);

      await db
          .into(db.foods)
          .insert(
            FoodsCompanion.insert(
              name: 'Avena',
              lowerName: 'avena',
              lastUsedAt: DateTime(2026, 3, 11),
            ),
          );

      expect(
        db
            .into(db.foods)
            .insert(
              FoodsCompanion.insert(
                name: 'AVENA',
                lowerName: 'avena',
                lastUsedAt: DateTime(2026, 3, 12),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('carries the water index up from before the table existed', () async {
    // Same trap as every other index here: `createTable` writes the table
    // and nothing else, so a database that arrived through the migration
    // would read a day of drinks with a full scan.
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);

    final indices = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'index' AND name = 'water_by_day'",
        )
        .get();

    expect(indices, hasLength(1));
  });

  test(
    'leaves the training already logged with nothing said about it',
    () async {
      // The video and the note are both null for everything already stored,
      // and that is the honest answer: nobody was asked, so nobody answered.
      final schema = await verifier.schemaAt(8);
      final day = DateTime(2026, 3, 11);

      final before = v8.DatabaseAtV8(schema.newConnection());
      final exerciseId = await before
          .into(before.exercises)
          .insert(v8.ExercisesCompanion.insert(name: 'Sentadilla'));
      await before
          .into(before.exerciseSets)
          .insert(
            v8.ExerciseSetsCompanion.insert(
              exerciseId: exerciseId,
              date: day.millisecondsSinceEpoch ~/ 1000,
              reps: 8,
            ),
          );
      await before.close();

      final db = AppDatabase.forTesting(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 11);

      final exercise = await db.select(db.exercises).getSingle();
      expect(exercise.name, 'Sentadilla');
      expect(exercise.videoUrl, isNull);

      final set = await db.select(db.exerciseSets).getSingle();
      expect(set.reps, 8);
      expect(set.note, isNull);
    },
  );

  test('drops the routine tables v9 introduced', () async {
    // v9 kept the plan and the record apart and compared them when reading.
    // v10 replaced it with one row per exercise per day, and the old tables
    // go rather than linger: a table nothing reads is a question every later
    // reader has to answer.
    final schema = await verifier.schemaAt(9);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);

    final leftovers = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('routines', 'routine_exercises')",
        )
        .get();

    expect(leftovers, isEmpty);
  });

  test(
    'cascades a deleted movement onto the days it was scheduled on',
    () async {
      // The scheduled day describes that movement. What it never owns is the
      // rest of the day around it.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase.forTesting(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 11);

      final exerciseId = await db
          .into(db.exercises)
          .insert(ExercisesCompanion.insert(name: 'Sentadilla'));
      await db
          .into(db.scheduledExercises)
          .insert(
            ScheduledExercisesCompanion.insert(
              exerciseId: exerciseId,
              scheduledDate: DateTime(2026, 3, 9),
              sets: 4,
              reps: 8,
            ),
          );

      await (db.delete(
        db.exercises,
      )..where((e) => e.id.equals(exerciseId))).go();

      expect(await db.select(db.scheduledExercises).get(), isEmpty);
    },
  );

  test(
    'carries the discipline indices up from before the table existed',
    () async {
      // Same trap as every other index here: `createTable` writes the table and
      // nothing else, so a database that arrived through the migration would
      // read a day of practice with a full scan.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase.forTesting(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 11);

      final indices = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name IN ('discipline_by_day', 'discipline_by_group')",
          )
          .get();

      expect(indices, hasLength(2));
    },
  );

  test('keeps foreign keys enforced after an upgrade', () async {
    // The pragma is set per connection in `beforeOpen`, and a migration opens
    // the database on its own terms. A cascade that stops cascading would
    // leave orphaned rows behind every delete.
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);

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
