import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/database/database_provider.dart';
import 'package:nisabit/core/widgets/stat_tile.dart';
import 'package:nisabit/features/habits/domain/habit_draft.dart';
import 'package:nisabit/features/habits/domain/habit_frequency.dart';
import 'package:nisabit/features/habits/presentation/habit_providers.dart';
import 'package:nisabit/features/habits/presentation/habits_screen.dart';
import 'package:nisabit/features/streaks/presentation/streak_providers.dart';
import 'package:nisabit/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
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
          // Pinned: these assertions read the Spanish copy, and the
          // test binding would otherwise pick the device default.
          locale: Locale('es'),
          home: HabitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the four frequency tabs', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Diario'), findsOneWidget);
    expect(find.text('Semanal'), findsOneWidget);
    expect(find.text('Mensual'), findsOneWidget);
    expect(find.text('Anual'), findsOneWidget);
  });

  testWidgets('shows both empty states when there is no data', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Todavía no hay rachas'), findsOneWidget);
    expect(find.text('Todavía no hay hábitos acá'), findsOneWidget);
  });

  testWidgets('lists a habit that exists', (tester) async {
    await container
        .read(habitActionsProvider)
        .create(
          const HabitDraft(
            name: 'Meditar 10 minutos',
            frequency: HabitFrequency.daily,
            category: 'Salud',
          ),
        );

    await pumpScreen(tester);

    expect(find.text('Meditar 10 minutos'), findsOneWidget);
    // Category and frequency share one muted line under the name.
    expect(find.text('Salud · Diario'), findsOneWidget);
    expect(find.byTooltip('Hecho'), findsOneWidget);
  });

  testWidgets('marks a habit as done when its button is tapped', (
    tester,
  ) async {
    await container
        .read(habitActionsProvider)
        .create(
          const HabitDraft(name: 'Leer', frequency: HabitFrequency.daily),
        );
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Hecho'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Completado'), findsOneWidget);
    expect(find.byTooltip('Hecho'), findsNothing);
  });

  testWidgets('reverts a completed habit when the circle is tapped again', (
    tester,
  ) async {
    await container
        .read(habitActionsProvider)
        .create(
          const HabitDraft(name: 'Leer', frequency: HabitFrequency.daily),
        );
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Hecho'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Completado'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hecho'), findsOneWidget);
  });

  testWidgets('keeps a weekly habit out of the daily tab', (tester) async {
    await container
        .read(habitActionsProvider)
        .create(
          const HabitDraft(
            name: 'Planificar la semana',
            frequency: HabitFrequency.weekly,
          ),
        );
    await pumpScreen(tester);

    expect(find.text('Planificar la semana'), findsNothing);

    await tester.tap(find.text('Semanal'));
    await tester.pumpAndSettle();

    expect(find.text('Planificar la semana'), findsOneWidget);
  });

  testWidgets('shows a streak with its counter and raises it', (tester) async {
    await container.read(streakActionsProvider).create('Días sin azúcar');
    await pumpScreen(tester);

    // The streak name is rendered as the tracked uppercase micro-label.
    expect(find.text('DÍAS SIN AZÚCAR'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byTooltip('+1'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Récord: 1'), findsOneWidget);
  });

  group('progress view', () {
    Future<void> openProgress(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Progreso'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers the four range presets', (tester) async {
      await pumpScreen(tester);
      await openProgress(tester);

      expect(find.text('Día'), findsOneWidget);
      expect(find.text('Semana'), findsOneWidget);
      expect(find.text('Mes'), findsOneWidget);
      expect(find.text('Año'), findsOneWidget);
    });

    testWidgets('starts on the thirty day window', (tester) async {
      await pumpScreen(tester);
      await openProgress(tester);

      expect(find.text('Últimos 30 días'), findsNWidgets(2));
    });

    testWidgets('shows an empty chart before anything is completed', (
      tester,
    ) async {
      await container
          .read(habitActionsProvider)
          .create(
            const HabitDraft(name: 'Leer', frequency: HabitFrequency.daily),
          );
      await pumpScreen(tester);
      await openProgress(tester);

      expect(find.text('COMPLETADOS'), findsOneWidget);
      expect(find.text('Sin datos en este rango'), findsNWidgets(2));
    });

    testWidgets('counts a completion and estimates the rate', (tester) async {
      await container
          .read(habitActionsProvider)
          .create(
            const HabitDraft(name: 'Leer', frequency: HabitFrequency.daily),
          );
      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Hecho'));
      await tester.pumpAndSettle();

      await openProgress(tester);

      // Scoped to the tile: the chart's y axis also renders a "1".
      expect(
        find.descendant(
          of: find.widgetWithText(StatTile, 'COMPLETADOS'),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      // One completion over one habit reads as a full rate.
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('hides the create button while looking at progress', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await openProgress(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('goes back to the list', (tester) async {
      await pumpScreen(tester);
      await openProgress(tester);

      await tester.tap(find.byTooltip('Lista'));
      await tester.pumpAndSettle();

      expect(find.text('Diario'), findsOneWidget);
    });
  });
}
