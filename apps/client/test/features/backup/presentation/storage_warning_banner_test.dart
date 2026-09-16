import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/database/storage_durability.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/backup/presentation/widgets/storage_warning_banner.dart';
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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    files = _FakeFiles();
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(
    WidgetTester tester,
    StorageDurability durability,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        databaseProvider.overrideWithValue(db),
        backupFilesProvider.overrideWithValue(files),
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
          // Pinned: these assertions read the English copy.
          locale: Locale('en'),
          home: Scaffold(body: StorageWarningBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('says nothing on storage that can be trusted', (tester) async {
    await pump(tester, StorageDurability.durable);

    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('warns that IndexedDB can lose data', (tester) async {
    await pump(tester, StorageDurability.degraded);

    expect(find.textContaining('may be lost'), findsOneWidget);
    expect(find.text('Export now'), findsOneWidget);
  });

  testWidgets('warns harder when nothing is stored at all', (tester) async {
    await pump(tester, StorageDurability.volatile);

    expect(find.textContaining('will be lost when you close'), findsOneWidget);
  });

  testWidgets('exports from the banner itself', (tester) async {
    await pump(tester, StorageDurability.degraded);

    await tester.tap(find.text('Export now'));
    await tester.pumpAndSettle();

    expect(files.savedContents, isNotNull);
  });

  testWidgets('goes away for the session once dismissed', (tester) async {
    final container = await pump(tester, StorageDurability.degraded);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsNothing);
    expect(container.read(storageWarningDismissedProvider), isTrue);
  });
}
