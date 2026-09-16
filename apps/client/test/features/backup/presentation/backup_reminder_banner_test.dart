import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/clock.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/backup/presentation/widgets/backup_reminder_banner.dart';
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
  final now = DateTime(2026, 9, 16, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    files = _FakeFiles();
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        backupFilesProvider.overrideWithValue(files),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        clockProvider.overrideWithValue(() => now),
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
          // Pinned: these assertions read the English copy.
          locale: Locale('en'),
          home: Scaffold(body: BackupReminderBanner()),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> seedHabit() => DriftHabitRepository(
    db,
  ).create(const HabitDraft(name: 'Meditar', frequency: HabitFrequency.daily));

  testWidgets('says nothing while there is nothing to back up', (tester) async {
    await pump(tester);

    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('reminds someone who has never exported', (tester) async {
    await seedHabit();
    await pump(tester);

    expect(find.text("You haven't backed up your data yet."), findsOneWidget);
  });

  testWidgets('says how long it has been since the last export', (
    tester,
  ) async {
    await seedHabit();
    await pump(
      tester,
      prefs: {
        'backup.lastExportAt': now
            .subtract(const Duration(days: 45))
            .toIso8601String(),
      },
    );

    expect(find.text('Your last backup was 45 days ago.'), findsOneWidget);
  });

  testWidgets('is snoozed when put off', (tester) async {
    await seedHabit();
    final container = await pump(tester);

    await tester.tap(find.text('Not now'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsNothing);
    expect(container.read(backupHistoryProvider).reminderDismissedAt, now);
  });

  testWidgets('exports, and then goes away', (tester) async {
    await seedHabit();
    await pump(tester);

    await tester.tap(find.text('Export'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(files.savedContents, isNotNull);
    expect(find.byType(MaterialBanner), findsNothing);
  });
}
