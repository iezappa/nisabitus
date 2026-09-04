import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';
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

  testWidgets('scales a food from the database by what it weighed', (
    tester,
  ) async {
    // The whole point of the reshape: the database quotes 100 g, the user
    // says what was on the plate, and the entry is the two multiplied out
    // where they can see it happen.
    await pumpView(tester);

    await tester.tap(find.byTooltip('Agregar alimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Base de alimentos'));
    await tester.pumpAndSettle();

    // Scoped to the dialog on top: the entry form is still behind it, and an
    // unscoped field finder types into that one instead.
    final database = find.byType(AlertDialog).last;

    // Eighty foods do not fit on a screen, so the search is how one is found.
    await tester.enterText(
      find.descendant(of: database, matching: find.byType(TextField)),
      'avena',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: database, matching: find.text('Avena')),
    );
    await tester.pumpAndSettle();

    // It lands at the weight the figure is quoted for, so what appears is
    // what the database actually holds.
    expect(find.widgetWithText(TextFormField, 'Avena'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '380'), findsOneWidget);

    final weight = find.ancestor(
      of: find.text('Peso'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(weight, '50');
    await tester.pumpAndSettle();

    // 380 kcal per 100 g, halved. Visible in the field before anything is
    // saved: scaling the user cannot see is scaling the user cannot check.
    expect(find.widgetWithText(TextFormField, '190'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '50 g'), findsOneWidget);
  });

  testWidgets('writes down a food the database did not have', (tester) async {
    // Finding out mid-entry that your breakfast is not listed must not mean
    // cancelling and starting over somewhere else.
    await pumpView(tester);

    await tester.tap(find.byTooltip('Agregar alimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Base de alimentos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alimento nuevo'));
    await tester.pumpAndSettle();

    // Scoped to the form on top: the entry form behind it has a name field
    // and a calories field of its own.
    final form = find.byType(AlertDialog).last;
    await tester.enterText(
      find.descendant(
        of: form,
        matching: find.widgetWithText(TextFormField, 'Nombre'),
      ),
      'Licuado de banana',
    );
    await tester.enterText(
      find.descendant(
        of: form,
        matching: find.ancestor(
          of: find.text('Calorías'),
          matching: find.byType(TextFormField),
        ),
      ),
      '90',
    );
    await tester.tap(find.descendant(of: form, matching: find.text('Guardar')));
    await tester.pumpAndSettle();

    final stored = await repository().foods();
    final mine = stored.firstWhere((f) => f.name == 'Licuado de banana');
    expect(mine.per100g.calories, 90);
    expect(mine.isBuiltIn, isFalse, reason: 'the user wrote it, not the app');

    // And it is offered back straight away, without closing anything. Found
    // by searching, because the list is alphabetical and eighty foods long —
    // which is the reason the search is there at all.
    final database = find.byType(AlertDialog).last;
    await tester.enterText(
      find.descendant(of: database, matching: find.byType(TextField)),
      'licuado',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: database, matching: find.text('Licuado de banana')),
      findsOneWidget,
    );
    // Marked as the user's own, so a later reseed knows to leave it alone.
    expect(
      find.descendant(of: database, matching: find.text('Tuyo')),
      findsOneWidget,
    );
  });
}
