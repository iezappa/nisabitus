import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/database/database_provider.dart';
import 'package:nisabit/features/backup/domain/backup_document.dart';
import 'package:nisabit/features/backup/domain/backup_files.dart';
import 'package:nisabit/features/backup/presentation/backup_providers.dart';
import 'package:nisabit/features/habits/data/drift_habit_repository.dart';
import 'package:nisabit/features/habits/domain/habit_draft.dart';
import 'package:nisabit/features/habits/domain/habit_frequency.dart';
import 'package:nisabit/features/habits/presentation/habit_providers.dart';

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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    files = _FakeFiles();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        backupFilesProvider.overrideWithValue(files),
      ],
    );
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
