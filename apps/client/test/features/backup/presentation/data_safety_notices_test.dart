import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/database/storage_durability.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/clock.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/backup/presentation/widgets/backup_reminder_banner.dart';
import 'package:nisabitus/features/backup/presentation/widgets/storage_warning_banner.dart';
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

/// Both data-safety banners ask for the same thing, so only one is docked at
/// a time: the storage warning first, the backup reminder once it is gone.
void main() {
  late AppDatabase db;
  late _FakeFiles files;
  final now = DateTime(2026, 9, 16, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    files = _FakeFiles();
  });
  tearDown(() => db.close());

  const storageWarning = 'This browser keeps your data';
  const reminder = "You haven't backed up your data yet.";

  Future<void> pump(WidgetTester tester, StorageDurability durability) async {
    await DriftHabitRepository(db).create(
      const HabitDraft(name: 'Meditar', frequency: HabitFrequency.daily),
    );
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        backupFilesProvider.overrideWithValue(files),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        clockProvider.overrideWithValue(() => now),
        storageDurabilityProvider.overrideWith((ref) => durability),
      ],
    );
    addTearDown(container.dispose);

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
          locale: Locale('en'),
          home: Scaffold(
            body: Column(
              children: [
                Spacer(),
                StorageWarningBanner(),
                BackupReminderBanner(),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('the storage warning takes the place of the reminder', (
    tester,
  ) async {
    await pump(tester, StorageDurability.degraded);

    expect(find.textContaining(storageWarning), findsOneWidget);
    expect(find.text(reminder), findsNothing);
    expect(find.byType(MaterialBanner), findsOneWidget);
  });

  testWidgets('the reminder comes back once the warning is dismissed', (
    tester,
  ) async {
    await pump(tester, StorageDurability.degraded);

    await tester.tap(find.text('Dismiss'));
    await settle(tester);

    expect(find.textContaining(storageWarning), findsNothing);
    expect(find.text(reminder), findsOneWidget);
  });

  testWidgets('an export from the warning also settles the reminder', (
    tester,
  ) async {
    await pump(tester, StorageDurability.degraded);

    await tester.tap(find.text('Export now'));
    await settle(tester);
    expect(files.savedContents, isNotNull);
    // The "exported" snackbar sits over the banner's buttons.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dismiss'));
    await settle(tester);

    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('durable storage leaves the reminder alone', (tester) async {
    await pump(tester, StorageDurability.durable);

    expect(find.text(reminder), findsOneWidget);
  });
}

/// Lets the database and preferences round-trips land, then the frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}
