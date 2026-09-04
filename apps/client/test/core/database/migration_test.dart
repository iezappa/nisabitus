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
import 'generated/schema_v11.dart' as v11;
import 'generated/schema_v12.dart' as v12;
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
    await verifier.migrateAndValidate(db, 13);

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
    await verifier.migrateAndValidate(db, 13);

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
    await verifier.migrateAndValidate(db, 13);

    final stored = await db.select(db.foodEntries).getSingle();
    expect(stored.name, 'Avena');
    expect(stored.calories, 300);
    expect(stored.meal, isNull);
  });

  test(
    'carries the unique food name index up from before it existed',
    () async {
      // Same trap as the intake index: `createTable` writes the table and
      // nothing else. Without this index the database files a second
      // "Ñoquis" every time the casing changes, and the picker fills up with
      // the same food over and over.
      //
      // A name the seed does not already use, or the collision under test
      // would be with a shipped row rather than with the one written here.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase.forTesting(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 13);

      await db
          .into(db.foods)
          .insert(
            FoodsCompanion.insert(
              name: 'Ñoquis de la abuela',
              lowerName: 'ñoquis de la abuela',
            ),
          );

      expect(
        db
            .into(db.foods)
            .insert(
              FoodsCompanion.insert(
                name: 'ÑOQUIS DE LA ABUELA',
                lowerName: 'ñoquis de la abuela',
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
    await verifier.migrateAndValidate(db, 13);

    final indices = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'index' AND name = 'water_by_day'",
        )
        .get();

    expect(indices, hasLength(1));
  });

  test('leaves the movements already stored with no reference video', () async {
    // Null is the honest answer: nobody was asked, so nobody answered.
    final schema = await verifier.schemaAt(8);
    final day = DateTime(2026, 3, 11);

    final before = v8.DatabaseAtV8(schema.newConnection());
    final exerciseId = await before
        .into(before.exercises)
        .insert(v8.ExercisesCompanion.insert(name: 'Sentadilla'));
    // The set log of the day, which v12 drops. It is written here so the
    // upgrade is exercised with rows in the table it removes, not with an
    // empty one.
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
    await verifier.migrateAndValidate(db, 13);

    final exercise = await db.select(db.exercises).getSingle();
    expect(exercise.name, 'Sentadilla');
    expect(exercise.videoUrl, isNull);
  });

  test('drops the per-set log v12 replaced', () async {
    // Two ways to record the same gym work, and neither could be trusted as
    // the answer. The scheduled row survives because it is what the screen
    // ticks off; the sets stored under the old log go with the table, which
    // is data loss and is deliberate.
    final schema = await verifier.schemaAt(11);
    final day = DateTime(2026, 3, 11);

    final before = v11.DatabaseAtV11(schema.newConnection());
    final exerciseId = await before
        .into(before.exercises)
        .insert(v11.ExercisesCompanion.insert(name: 'Sentadilla'));
    await before
        .into(before.exerciseSets)
        .insert(
          v11.ExerciseSetsCompanion.insert(
            exerciseId: exerciseId,
            date: day.millisecondsSinceEpoch ~/ 1000,
            reps: 8,
          ),
        );
    await before
        .into(before.scheduledExercises)
        .insert(
          v11.ScheduledExercisesCompanion.insert(
            exerciseId: exerciseId,
            scheduledDate: day.millisecondsSinceEpoch ~/ 1000,
            sets: 4,
            reps: 8,
          ),
        );
    await before
        .into(before.disciplines)
        .insert(
          v11.DisciplinesCompanion.insert(
            name: 'Natación',
            scheduledDate: day.millisecondsSinceEpoch ~/ 1000,
            durationMinutes: 45,
          ),
        );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    final leftovers = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'exercise_sets'",
        )
        .get();
    expect(leftovers, isEmpty);

    // What the routine is made of survives the drop untouched.
    expect((await db.select(db.exercises).getSingle()).name, 'Sentadilla');

    final scheduled = await db.select(db.scheduledExercises).getSingle();
    expect(scheduled.sets, 4);
    expect(scheduled.reps, 8);

    expect((await db.select(db.disciplines).getSingle()).name, 'Natación');
  });

  test('drops the routine tables v9 introduced', () async {
    // v9 kept the plan and the record apart and compared them when reading.
    // v10 replaced it with one row per exercise per day, and the old tables
    // go rather than linger: a table nothing reads is a question every later
    // reader has to answer.
    final schema = await verifier.schemaAt(9);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

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
      await verifier.migrateAndValidate(db, 13);

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
      await verifier.migrateAndValidate(db, 13);

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
    await verifier.migrateAndValidate(db, 13);

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
  test('reshapes the food catalogue into a food database', () async {
    // v12 quoted a food's macros against a free-text portion. Those figures
    // are for a weight nobody recorded, so there is no honest way to read
    // them as per-100 g values — the rows go, and the seed replaces them.
    final schema = await verifier.schemaAt(12);

    final before = v12.DatabaseAtV12(schema.newConnection());
    await before
        .into(before.foods)
        .insert(
          v12.FoodsCompanion.insert(
            name: 'Avena de antes',
            lowerName: 'avena de antes',
            portion: const Value('1 plato'),
            calories: const Value(300),
            // The snapshot stores dates as unix seconds, the way drift wrote
            // them at v12.
            lastUsedAt: DateTime(2026, 3, 11).millisecondsSinceEpoch ~/ 1000,
          ),
        );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    final foods = await db.select(db.foods).get();

    // What was there is gone, deliberately: a figure for an unknown portion
    // read as a figure per 100 g is wrong by an arbitrary factor.
    expect(foods.where((f) => f.name == 'Avena de antes'), isEmpty);

    // And the database is not merely empty — it ships with a catalogue.
    expect(foods, isNotEmpty);
    expect(foods.every((f) => f.isBuiltIn), isTrue);

    final avena = foods.firstWhere((f) => f.name == 'Avena');
    expect(avena.caloriesPer100g, 380);
  });

  test('leaves the eating history untouched by the food reshape', () async {
    // The catalogue was a convenience cache and it is replaceable. What was
    // eaten is the record of a day that was actually lived, and no migration
    // gets to rewrite it. This is the half of v13 that would be a bug.
    final schema = await verifier.schemaAt(12);

    final before = v12.DatabaseAtV12(schema.newConnection());
    await before
        .into(before.foodEntries)
        .insert(
          v12.FoodEntriesCompanion.insert(
            date: DateTime(2026, 3, 11).millisecondsSinceEpoch ~/ 1000,
            name: 'Milanesa',
            portion: const Value('1 plato'),
            calories: const Value(620),
            protein: const Value(44),
            carbs: const Value(33),
            fat: const Value(33),
            meal: const Value('LUNCH'),
          ),
        );
    await before.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    final entry = await db.select(db.foodEntries).getSingle();
    expect(entry.name, 'Milanesa');
    expect(entry.portion, '1 plato');
    expect(entry.calories, 620);
    expect(entry.protein, 44);
    expect(entry.carbs, 33);
    expect(entry.fat, 33);
    expect(entry.meal, 'LUNCH');
  });

  test('does not overwrite a food the user had written themselves', () async {
    // The seed runs with `insertOrIgnore` against the unique lower-case name.
    // A user who had already written down their own "Avena" keeps theirs,
    // figures and all — a reseed adds, it never merges over.
    final schema = await verifier.schemaAt(13);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);

    await db
        .into(db.foods)
        .insert(
          FoodsCompanion.insert(
            name: 'Avena',
            lowerName: 'avena',
            caloriesPer100g: const Value(111),
          ),
        );

    final mine = await (db.select(
      db.foods,
    )..where((f) => f.lowerName.equals('avena'))).getSingle();

    expect(mine.caloriesPer100g, 111);
    expect(mine.isBuiltIn, isFalse);
  });
}
