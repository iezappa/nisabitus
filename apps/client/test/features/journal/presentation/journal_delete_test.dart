import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/journal/data/drift_journal_repository.dart';
import 'package:nisabitus/features/journal/domain/journal_content.dart';
import 'package:nisabitus/features/journal/presentation/journal_screen.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/refuse_writes.dart';

void main() {
  final wednesday = DateTime(2026, 3, 11);

  testWidgets('says so when the entry could not be deleted', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await DriftJournalRepository(db)
        .save(wednesday, const JournalContent(reflection: 'Buen día'));
    await refuseWrites(db, 'mood_entries', operation: 'DELETE');
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          todayProvider.overrideWithValue(wednesday),
          selectedDayProvider.overrideWith((ref) => wednesday),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: JournalScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo borrar. Intentá de nuevo.'), findsOneWidget);
    expect(await DriftJournalRepository(db).forDay(wednesday), isNotNull);

    // Let the drift streams close before the database does.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
