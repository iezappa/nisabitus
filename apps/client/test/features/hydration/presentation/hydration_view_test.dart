import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/hydration/domain/hydration.dart';
import 'package:nisabitus/features/hydration/domain/hydration_repository.dart';
import 'package:nisabitus/features/hydration/presentation/hydration_providers.dart';
import 'package:nisabitus/features/hydration/presentation/hydration_view.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final day = DateTime(2026, 3, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(day),
        selectedDayProvider.overrideWith((ref) => day),
      ],
    );
    addTearDown(container.dispose);
  });
  tearDown(() => db.close());

  HydrationRepository repository() =>
      container.read(hydrationRepositoryProvider);

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          home: Scaffold(body: HydrationView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('writes down a glass in one tap', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('200 ml'));
    await tester.pumpAndSettle();

    expect((await repository().entriesFor(day)).single.millilitres, 200);
  });

  testWidgets('adds each glass up rather than replacing the last', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.tap(find.text('200 ml'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('500 ml'));
    await tester.pumpAndSettle();

    expect(await repository().entriesFor(day), hasLength(2));
    expect(find.text('700'), findsOneWidget);
  });

  testWidgets('takes a glass back', (tester) async {
    await repository().addEntry(day, 250);
    await pumpView(tester);

    await tester.tap(find.byTooltip('Borrar'));
    await tester.pumpAndSettle();

    expect(await repository().entriesFor(day), isEmpty);
  });

  testWidgets('says what is left of the target', (tester) async {
    await repository().saveGoal(HydrationGoal(millilitres: 2000));
    await repository().addEntry(day, 500);
    await pumpView(tester);

    expect(find.text('Te faltan 1500 ml'), findsOneWidget);
  });

  testWidgets('says the target was reached without scolding what came after', (
    tester,
  ) async {
    // A log, not a nurse. Drinking past the target is not a mistake to be
    // reported back in red.
    await repository().saveGoal(HydrationGoal(millilitres: 1000));
    await repository().addEntry(day, 1500);
    await pumpView(tester);

    expect(find.text('Llegaste al objetivo'), findsOneWidget);
  });

  testWidgets('collects an odd-sized drink through the form', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Otra cantidad'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '330');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect((await repository().entriesFor(day)).single.millilitres, 330);
  });

  testWidgets('refuses a drink of nothing at the form rather than at the '
      'database', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Otra cantidad'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ingresá un número'), findsOneWidget);
    expect(await repository().entriesFor(day), isEmpty);
  });
}
