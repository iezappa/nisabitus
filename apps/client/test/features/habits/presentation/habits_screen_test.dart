import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/database/database_provider.dart';
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
    expect(find.text('SALUD'), findsOneWidget);
    expect(find.text('Hecho'), findsOneWidget);
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

    await tester.tap(find.text('Hecho'));
    await tester.pumpAndSettle();

    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Hecho'), findsNothing);
  });

  testWidgets('reverts a completed habit when the chip is tapped', (
    tester,
  ) async {
    await container
        .read(habitActionsProvider)
        .create(
          const HabitDraft(name: 'Leer', frequency: HabitFrequency.daily),
        );
    await pumpScreen(tester);
    await tester.tap(find.text('Hecho'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completado'));
    await tester.pumpAndSettle();

    expect(find.text('Hecho'), findsOneWidget);
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

    expect(find.text('Días sin azúcar'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Récord: 1'), findsOneWidget);
  });
}
