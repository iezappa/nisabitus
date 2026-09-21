import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/medication/data/drift_medication_repository.dart';
import 'package:nisabitus/features/medication/domain/medication.dart';
import 'package:nisabitus/features/medication/domain/medication_repository.dart';
import 'package:nisabitus/features/medication/presentation/medication_view.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    await DriftMedicationRepository(db).create(
      const MedicationDraft(
        name: 'Vitamina D',
        kind: MedicationKind.supplement,
      ),
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
          home: Scaffold(body: MedicationView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the catalogue starts folded away', (tester) async {
    // What is due today is why this screen is opened; the list of everything
    // the user takes is reference, and reference that is always unrolled
    // pushes the day's work off the screen.
    //
    // Counted rather than absent: the same medication is also in the day's
    // list above, which is the half that must never fold away.
    await pump(tester);

    expect(find.text('Vitamina D'), findsOne);
  });

  testWidgets('says how many are in there while it is closed', (tester) async {
    // Folding it away must not also hide whether there is anything in it.
    await pump(tester);

    expect(find.text('LO QUE TOMÁS · 1'), findsOne);
  });

  testWidgets('the whole header opens it, not just the chevron', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('LO QUE TOMÁS · 1'));
    await tester.pumpAndSettle();

    // Once in the day's list, once in the catalogue that just opened.
    expect(find.text('Vitamina D'), findsNWidgets(2));
    expect(container.read(medicationCatalogueExpandedProvider), isTrue);
    // The count goes once the list is there to be counted by eye.
    expect(find.text('LO QUE TOMÁS'), findsOne);
  });

  testWidgets('what is due today is never folded away', (tester) async {
    await pump(tester);

    expect(find.text('PARA ESE DÍA'), findsOne);
  });
}
