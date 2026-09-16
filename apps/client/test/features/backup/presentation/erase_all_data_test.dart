import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/app/app_restart.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/backup/presentation/widgets/erase_all_data_tile.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFiles implements BackupFiles {
  String? savedContents;

  @override
  Future<bool> save(String fileName, String contents) async {
    savedContents = contents;
    return true;
  }

  @override
  Future<String?> open() async => null;
}

void main() {
  late AppDatabase db;
  late _FakeFiles files;
  late SharedPreferences prefs;
  late ProviderContainer container;
  late int restarts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'settings.language': 'en',
      'settings.theme': 'dark',
      'settings.accent': 'plum',
      'settings.onboardingDone': true,
      'settings.backupNoticeAccepted': true,
      'settings.profileName': 'Zeke',
      'settings.hiddenTabs': ['todo'],
      'backup.lastExportAt': '2026-09-01T10:00:00.000',
      'releaseNotes.lastSeenVersion': '1.1.0',
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    files = _FakeFiles();
    restarts = 0;
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        backupFilesProvider.overrideWithValue(files),
        sharedPreferencesProvider.overrideWithValue(prefs),
        restartAppProvider.overrideWithValue(() => restarts++),
      ],
    );
    await DriftHabitRepository(db).create(
      const HabitDraft(name: 'Meditar', frequency: HabitFrequency.daily),
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  group('EraseAllDataActions', () {
    test('wipes the store', () async {
      await container.read(eraseAllDataActionsProvider).eraseEverything();

      expect(await db.select(db.habits).get(), isEmpty);
    });

    test('forgets every preference but how the app looks and speaks', () async {
      await container.read(eraseAllDataActionsProvider).eraseEverything();

      expect(prefs.getKeys(), {
        'settings.language',
        'settings.theme',
        'settings.accent',
      });
    });

    test('starts the app over, which lands on onboarding', () async {
      await container.read(eraseAllDataActionsProvider).eraseEverything();

      expect(restarts, 1);
      expect(prefs.getBool('settings.onboardingDone'), isNull);
    });
  });

  group('the confirmation', () {
    Future<void> open(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            // Pinned: these assertions read the English copy.
            locale: Locale('en'),
            home: Scaffold(body: EraseAllDataTile()),
          ),
        ),
      );
      await tester.tap(find.text('Delete all my data'));
      await tester.pumpAndSettle();
    }

    FilledButton eraseButton(WidgetTester tester) =>
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Delete everything'),
        );

    testWidgets('will not delete until the word is typed', (tester) async {
      await open(tester);

      expect(eraseButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'delete it');
      await tester.pump();
      expect(eraseButton(tester).onPressed, isNull);
    });

    testWidgets('offers to export first', (tester) async {
      await open(tester);

      await tester.tap(find.text('Export first'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(files.savedContents, isNotNull);
      expect(restarts, 0);
    });

    testWidgets('backing out deletes nothing', (tester) async {
      await open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await db.select(db.habits).get(), hasLength(1));
      expect(restarts, 0);
    });

    testWidgets('deletes once the word is typed and confirmed', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      await tester.tap(find.text('Delete everything'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(restarts, 1);
      expect(await tester.runAsync(() => db.select(db.habits).get()), isEmpty);
    });
  });
}
