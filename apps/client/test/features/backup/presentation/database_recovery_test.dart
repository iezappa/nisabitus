import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/app/app_restart.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_health.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/database/local_store.dart';
import 'package:nisabitus/features/backup/data/drift_backup_repository.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/backup/presentation/database_gate.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

class _FakeFiles implements BackupFiles {
  String? toOpen;

  @override
  Future<bool> save(String fileName, String contents) async => true;

  @override
  Future<String?> open() async => toOpen;
}

void main() {
  late Directory dir;
  late File file;
  late _FakeFiles files;
  late int restarts;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nisabitus_recovery_');
    file = File('${dir.path}/store.sqlite')
      ..writeAsStringSync('not a database, and never was');
    files = _FakeFiles();
    restarts = 0;
    container = ProviderContainer(
      overrides: [
        // A factory, not a value: recovery throws the broken connection away
        // and needs a new one on the same file.
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.forTesting(NativeDatabase(file));
          ref.onDispose(db.close);
          return db;
        }),
        eraseLocalStoreProvider.overrideWithValue(() async {
          if (file.existsSync()) file.deleteSync();
        }),
        backupFilesProvider.overrideWithValue(files),
        restartAppProvider.overrideWithValue(() => restarts++),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<String> backupWithOneHabit() async {
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    await DriftHabitRepository(source).create(
      const HabitDraft(name: 'Meditar', frequency: HabitFrequency.daily),
    );
    return (await DriftBackupRepository(source).export()).encode();
  }

  group('DatabaseRecoveryActions', () {
    test('reset throws the broken store away and restarts the app', () async {
      await container.read(databaseRecoveryActionsProvider).reset();

      expect(file.existsSync(), isFalse);
      expect(restarts, 1);
    });

    test('import restores the backup into a fresh store', () async {
      files.toOpen = await backupWithOneHabit();

      final outcome = await container
          .read(databaseRecoveryActionsProvider)
          .importBackup();

      expect(outcome, isA<BackupSucceeded>());
      expect(restarts, 1);
      final db = container.read(databaseProvider);
      expect(await probeDatabase(db), isA<DatabaseHealthy>());
      expect(await db.select(db.habits).get(), hasLength(1));
    });

    test('import touches nothing when the file is not a backup', () async {
      files.toOpen = 'querido diario';

      final outcome = await container
          .read(databaseRecoveryActionsProvider)
          .importBackup();

      expect(outcome, isA<BackupRejected>());
      expect(file.existsSync(), isTrue);
      expect(restarts, 0);
    });

    test('import touches nothing when the user backs out', () async {
      final outcome = await container
          .read(databaseRecoveryActionsProvider)
          .importBackup();

      expect(outcome, isA<BackupCancelled>());
      expect(file.existsSync(), isTrue);
    });
  });

  group('DatabaseGate', () {
    Future<void> pump(WidgetTester tester, DatabaseHealth health) async {
      final gated = ProviderContainer(
        parent: container,
        overrides: [databaseHealthProvider.overrideWith((ref) async => health)],
      );
      addTearDown(gated.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: gated,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            // Pinned: these assertions read the English copy.
            locale: const Locale('en'),
            builder: (context, child) =>
                DatabaseGate(child: child ?? const SizedBox()),
            home: const Scaffold(body: Text('the app')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lets a healthy store through to the app', (tester) async {
      await pump(tester, const DatabaseHealthy());

      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('shows recovery instead of an app that cannot read', (
      tester,
    ) async {
      await pump(tester, DatabaseUnopenable(Exception('boom')));

      expect(find.text('the app'), findsNothing);
      expect(find.text('Import a backup'), findsOneWidget);
      expect(find.text('Reset local database'), findsOneWidget);
    });

    testWidgets('asks before resetting, and says the data goes', (
      tester,
    ) async {
      await pump(tester, DatabaseUnopenable(Exception('boom')));

      await tester.tap(find.text('Reset local database'));
      await tester.pumpAndSettle();

      expect(find.textContaining('permanently deleted'), findsOneWidget);
      expect(file.existsSync(), isTrue);
      expect(restarts, 0);
    });

    testWidgets('resets once confirmed', (tester) async {
      await pump(tester, DatabaseUnopenable(Exception('boom')));

      await tester.tap(find.text('Reset local database'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(restarts, 1);
    });
  });
}
