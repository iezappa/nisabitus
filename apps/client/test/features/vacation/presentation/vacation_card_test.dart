import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/vacation/domain/vacation.dart';
import 'package:nisabitus/features/vacation/presentation/vacation_providers.dart';
import 'package:nisabitus/features/vacation/presentation/widgets/vacation_card.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final wednesday = DateTime(2026, 3, 11);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        todayProvider.overrideWithValue(wednesday),
        selectedDayProvider.overrideWith((ref) => wednesday),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> pumpCard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
          locale: Locale('es'),
          home: Scaffold(body: SingleChildScrollView(child: VacationCard())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<List<VacationPeriod>> stored() =>
      container.read(vacationRepositoryProvider).list();

  testWidgets('starts switched off, with nothing written down', (tester) async {
    await pumpCard(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Todavía no anotaste ningún período.'), findsOneWidget);
  });

  testWidgets('opens a break today when switched on', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final period = (await stored()).single;
    expect(period.start, wednesday);
    expect(period.isOpenEnded, isTrue, reason: 'until the user says otherwise');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('closes the break when switched off', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect((await stored()).single.endsOn, wednesday);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('writes down a break that already happened', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Agregar período'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(await stored(), hasLength(1));
    // Today by default, and still open: the switch's own case, reached the
    // long way round.
    expect((await stored()).single.start, wednesday);
  });

  testWidgets('says how long a break lasted', (tester) async {
    await container
        .read(vacationRepositoryProvider)
        .add(
          VacationDraft(start: DateTime(2026, 3, 2), end: DateTime(2026, 3, 6)),
        );
    await pumpCard(tester);

    expect(find.textContaining('5 días'), findsOneWidget);
  });

  testWidgets('deletes a break from its own form', (tester) async {
    await container
        .read(vacationRepositoryProvider)
        .add(VacationDraft(start: DateTime(2026, 3, 2)));
    await pumpCard(tester);

    await tester.tap(find.byIcon(Icons.beach_access_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(await stored(), isEmpty);
  });
}
