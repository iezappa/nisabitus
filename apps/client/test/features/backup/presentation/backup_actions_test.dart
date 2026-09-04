import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/features/backup/domain/backup_document.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/features/habits/presentation/habit_providers.dart';

/// Stands in for the native dialogs: remembers what was written and hands
/// back whatever the test says the user picked.
class _FakeFiles implements BackupFiles {
  /// What the user picks on import, or null for backing out.
  String? toOpen;

  /// Whether the user goes through with the save dialog.
  bool accepted = true;

  String? savedName;
  String? savedContents;

  @override
  Future<bool> save(String fileName, String contents) async {
    if (!accepted) return false;

    savedName = fileName;
    savedContents = contents;
    return true;
  }

  @override
  Future<String?> open() async => toOpen;
}

void main() {
  late AppDatabase db;
  late _FakeFiles files;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    files = _FakeFiles();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        backupFilesProvider.overrideWithValue(files),
      ],
    );
    // The food database ships seeded, so a brand new store already holds
    // eighty-odd rows. Cleared here because these tests count what the backup
    // carried, and that arithmetic is about what the test wrote down.
    await db.delete(db.foods).go();
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  BackupActions actions() => container.read(backupActionsProvider);

  Future<void> seedHabit([String name = 'Meditar']) =>
      DriftHabitRepository(db)
          .create(HabitDraft(name: name, frequency: HabitFrequency.daily));

  group('export', () {
    test('hands the picker a document it can read back', () async {
      await seedHabit();

      final outcome = await actions().export();

      expect(outcome, isA<BackupSucceeded>());
      final written = BackupDocument.parse(
        files.savedContents!,
        supportedSchemaVersion: db.schemaVersion,
      );
      expect(written.tables['habits'], hasLength(1));
    });

    test('names the file after the day it was taken', () async {
      await actions().export();

      expect(
        files.savedName,
        matches(RegExp(r'^nisabit-\d{4}-\d{2}-\d{2}\.json$')),
      );
    });

    test('reports how much it wrote', () async {
      await seedHabit('Uno');
      await seedHabit('Dos');

      final outcome = await actions().export();

      expect((outcome as BackupSucceeded).rows, 2);
    });

    test('backing out of the dialog is not a failure', () async {
      files.accepted = false;

      expect(await actions().export(), isA<BackupCancelled>());
    });
  });

  group('import', () {
    Future<String> exportedText() async {
      await actions().export();
      return files.savedContents!;
    }

    test('restores the file the user picked', () async {
      await seedHabit();
      files.toOpen = await exportedText();
      await db.delete(db.habits).go();

      final outcome = await actions().import();

      expect(outcome, isA<BackupSucceeded>());
      expect((outcome as BackupSucceeded).rows, 1);
      expect(await db.select(db.habits).get(), hasLength(1));
    });

    test('backing out of the dialog is not a failure', () async {
      files.toOpen = null;

      expect(await actions().import(), isA<BackupCancelled>());
    });

    test('counts what came in, not what the file claimed', () async {
      // A backup taken before v12 carries the per-set log, and that table is
      // gone. The rows cannot be placed, so they cannot be counted, and the
      // message says part of the file was left behind.
      await seedHabit();
      final exported = jsonDecode(await exportedText()) as Map<String, dynamic>;
      (exported['tables'] as Map<String, dynamic>)['exercise_sets'] = [
        {'id': 1, 'exercise_id': 1, 'date': 0, 'position': 0, 'reps': 8},
      ];
      exported['schemaVersion'] = 11;
      files.toOpen = jsonEncode(exported);

      final outcome = await actions().import() as BackupSucceeded;

      expect(outcome.rows, 1);
      expect(outcome.ignoredTables, {'exercise_sets'});
    });

    test('refuses a file that is not a backup', () async {
      files.toOpen = 'querido diario, hoy...';

      final outcome = await actions().import();

      expect((outcome as BackupRejected).problem, BackupProblem.notABackup);
    });

    test('refuses a backup from a newer version', () async {
      await seedHabit();
      final newer = jsonDecode(await exportedText()) as Map<String, dynamic>
        ..['schemaVersion'] = db.schemaVersion + 1;
      files.toOpen = jsonEncode(newer);

      final outcome = await actions().import();

      expect((outcome as BackupRejected).problem, BackupProblem.newerVersion);
    });

    test('leaves the store alone when the file is refused', () async {
      await seedHabit();
      files.toOpen = 'no.';

      await actions().import();

      expect(await db.select(db.habits).get(), hasLength(1));
    });

    test('makes the modules reload what they were showing', () async {
      await seedHabit();
      files.toOpen = await exportedText();
      final before = container.read(habitsRevisionProvider);

      await actions().import();

      // Every module caches behind a revision counter, so a restore that
      // does not bump them leaves the screens showing the old store.
      expect(container.read(habitsRevisionProvider), greaterThan(before));
    });
  });
}
