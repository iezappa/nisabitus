import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/features/backup/domain/backup_files.dart';
import 'package:nisabitus/features/backup/presentation/backup_providers.dart';
import 'package:nisabitus/features/backup/presentation/widgets/backup_card.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

/// Stands in for the native dialogs.
class _FakeFiles implements BackupFiles {
  String? toOpen;
  String? savedContents;
  int opened = 0;

  @override
  Future<bool> save(String fileName, String contents) async {
    savedContents = contents;
    return true;
  }

  @override
  Future<String?> open() async {
    opened++;
    return toOpen;
  }
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

  Future<void> pump(WidgetTester tester) async {
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
          // Pinned: these assertions read the Spanish copy.
          locale: Locale('es'),
          home: Scaffold(body: BackupCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedHabit() => DriftHabitRepository(
    db,
  ).create(const HabitDraft(name: 'Meditar', frequency: HabitFrequency.daily));

  testWidgets('says what importing does before it is pressed', (tester) async {
    await pump(tester);

    expect(find.text('Importar reemplaza todo lo que tenés ahora.'), findsOne);
  });

  testWidgets('exports and says how much it wrote', (tester) async {
    await seedHabit();
    await pump(tester);

    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    expect(files.savedContents, isNotNull);
    expect(find.text('Copia guardada: 1 registro'), findsOne);
  });

  testWidgets('asks before replacing anything', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Reemplazar todos tus datos?'), findsOne);
    // The file dialog has not been opened yet: the question comes first.
    expect(files.opened, 0);
  });

  testWidgets('does nothing at all when the question is declined', (
    tester,
  ) async {
    await seedHabit();
    await pump(tester);

    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(files.opened, 0);
    expect(await db.select(db.habits).get(), hasLength(1));
  });

  testWidgets('explains a file that is not a backup', (tester) async {
    files.toOpen = 'querido diario, hoy...';
    await pump(tester);

    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reemplazar'));
    await tester.pumpAndSettle();

    expect(find.text('Ese archivo no es una copia de Nisabitus'), findsOne);
  });

  testWidgets('restores a confirmed file and says how much came in', (
    tester,
  ) async {
    await seedHabit();
    await pump(tester);
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    files.toOpen = files.savedContents;
    await db.delete(db.habits).go();

    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reemplazar'));
    await tester.pumpAndSettle();

    expect(await db.select(db.habits).get(), hasLength(1));
    expect(find.text('Datos restaurados: 1 registro'), findsOne);
  });
}
