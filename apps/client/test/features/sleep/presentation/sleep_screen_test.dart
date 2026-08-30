import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/database/database_provider.dart';
import 'package:nisabit/core/preferences/preferences.dart';
import 'package:nisabit/core/time/selected_day_provider.dart';
import 'package:nisabit/features/sleep/presentation/sleep_providers.dart';
import 'package:nisabit/features/health/presentation/health_screen.dart';
import 'package:nisabit/features/sleep/presentation/widgets/sleep_insights_card.dart';
import 'package:nisabit/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  // A Wednesday, so the strip has days on both sides of the selection.
  final wednesday = DateTime(2026, 3, 11);
  final monday = DateTime(2026, 3, 9);

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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          home: HealthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Flips the module to its progress side, where the history now lives.
  Future<void> showProgress(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.insights));
    await tester.pumpAndSettle();
  }

  group('the day strip', () {
    testWidgets('shows the seven days of the selected week', (tester) async {
      await pumpScreen(tester);

      for (final day in [9, 10, 11, 12, 13, 14, 15]) {
        expect(find.text('$day'), findsWidgets, reason: 'day $day is missing');
      }
    });

    testWidgets('cannot move past the week holding today', (tester) async {
      await pumpScreen(tester);

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );

      expect(next.onPressed, isNull);
    });

    testWidgets('moves the selection to another day', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();

      expect(container.read(selectedDayProvider), monday);
    });
  });

  group('the night card', () {
    testWidgets('says there is no record yet', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Sin registro'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('shows the hours and the derived quality once saved', (
      tester,
    ) async {
      await container.read(sleepActionsProvider).save(7.5);
      await pumpScreen(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sleep.night-card')),
          matching: find.text('7.5 h'),
        ),
        findsOneWidget,
      );
      expect(find.text('Óptimo'), findsOneWidget);
      // The button admits it is about to replace the record.
      expect(find.text('Actualizar'), findsOneWidget);
    });

    testWidgets('calls a short night poor', (tester) async {
      await container.read(sleepActionsProvider).save(4);
      await pumpScreen(tester);

      expect(find.text('A mejorar'), findsOneWidget);
    });
  });

  group('the form', () {
    testWidgets('registers the hours typed in', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), '8');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(container.read(sleepForSelectedDayProvider).value?.hours, 8);
    });

    testWidgets('refuses hours beyond a day', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), '30');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un número entre 0 y 24'), findsOneWidget);
      expect(container.read(sleepForSelectedDayProvider).value, isNull);
    });

    testWidgets('accepts a comma as the decimal separator', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), '6,5');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(container.read(sleepForSelectedDayProvider).value?.hours, 6.5);
    });
  });

  group('the history', () {
    testWidgets('is empty until a night is registered', (tester) async {
      await pumpScreen(tester);
      await showProgress(tester);

      expect(find.text('Sin datos en este rango'), findsOneWidget);
    });

    testWidgets('summarizes the nights registered', (tester) async {
      await container.read(sleepActionsProvider).save(8);
      await pumpScreen(tester);
      await showProgress(tester);

      expect(find.text('PROMEDIO'), findsOneWidget);
      expect(find.text('8.0 h'), findsOneWidget);
      expect(find.text('REGISTROS'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('remembers that the insights card was collapsed', (
      tester,
    ) async {
      await container.read(sleepActionsProvider).save(8);
      await pumpScreen(tester);
      await showProgress(tester);

      expect(find.text('Tus noches son parejas.'), findsOneWidget);

      await tester.tap(find.text('BIENESTAR'));
      await tester.pumpAndSettle();

      expect(find.text('Tus noches son parejas.'), findsNothing);
      expect(container.read(sleepInsightsExpandedProvider), isFalse);
    });
  });
}
