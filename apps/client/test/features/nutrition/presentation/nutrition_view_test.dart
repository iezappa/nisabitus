import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition_repository.dart';
import 'package:nisabitus/features/nutrition/presentation/nutrition_providers.dart';
import 'package:nisabitus/features/nutrition/presentation/nutrition_view.dart';
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

  NutritionRepository repository() =>
      container.read(nutritionRepositoryProvider);

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
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
          home: Scaffold(body: NutritionView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers a way to write down what was eaten', (tester) async {
    // This is the test that would have caught the screen shipping with no
    // way in at all: `add` existed on the actions and nothing called it, so
    // the only entries that could ever appear were seeded by a test.
    await pumpView(tester);

    expect(find.byTooltip('Agregar alimento'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar alimento'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar alimento'), findsWidgets);
  });

  testWidgets('writes down what the form collected', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byTooltip('Agregar alimento'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Avena',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect((await repository().entriesFor(day)).single.name, 'Avena');
  });

  testWidgets('sorts the day under one heading per meal', (tester) async {
    await repository().addEntry(
      day,
      const FoodDraft(name: 'Avena', meal: Meal.breakfast),
    );
    await repository().addEntry(
      day,
      const FoodDraft(name: 'Pollo', meal: Meal.lunch),
    );
    await pumpView(tester);

    expect(find.text('DESAYUNO'), findsOneWidget);
    expect(find.text('ALMUERZO'), findsOneWidget);
    // Nothing was eaten at dinner, so there is no dinner heading standing
    // over an empty list.
    expect(find.text('CENA'), findsNothing);
  });

  testWidgets('keeps the food that never said which meal it was', (
    tester,
  ) async {
    await repository().addEntry(day, const FoodDraft(name: 'Algo'));
    await pumpView(tester);

    expect(find.text('SIN ASIGNAR'), findsOneWidget);
    expect(find.text('Algo'), findsOneWidget);
  });

  testWidgets('offers back a food that was eaten before', (tester) async {
    // The catalogue fills itself from what was saved, so eating the same
    // breakfast twice is picking it the second time.
    await repository().addEntry(
      day,
      const FoodDraft(
        name: 'Avena',
        portion: '80 g',
        macros: Macros(calories: 300),
      ),
    );
    await pumpView(tester);

    await tester.tap(find.byTooltip('Agregar alimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir de lo que comés seguido'));
    await tester.pumpAndSettle();

    // Scoped to the picker: the entry it was learned from is still on the
    // screen behind the dialog, so a bare text finder matches twice.
    final picker = find.widgetWithText(AlertDialog, 'Lo que comés seguido');
    final offered = find.descendant(of: picker, matching: find.text('Avena'));
    expect(offered, findsOneWidget);

    await tester.tap(offered);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextFormField, 'Avena'),
      findsOneWidget,
      reason: 'picking a food fills the form with it',
    );
  });
}
