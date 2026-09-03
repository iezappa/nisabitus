import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/health/presentation/health_screen.dart';
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

  Future<void> pumpScreen(WidgetTester tester) async {
    // Wide enough for all five scrollable tabs to be on screen: a tab
    // scrolled out of view cannot be tapped.
    //
    // Through `tester.view`, not `setSurfaceSize`: that one resizes the
    // surface the tree is painted on but leaves MediaQuery reporting the
    // default 800x600, so the tabs lay themselves out for a window narrower
    // than the one they are painted into and scroll off it anyway.
    tester.view.physicalSize = const Size(1200, 1400);
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
          home: HealthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toggleProgress(WidgetTester tester) async {
    await tester.tap(
      find.byIcon(
        find.byIcon(Icons.insights).evaluate().isEmpty
            ? Icons.format_list_bulleted
            : Icons.insights,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    // Brought into view first. The tab strip scrolls because the page is
    // capped at a reading width, so widening the window does not put the
    // last tabs on screen — and a tab scrolled out of view cannot be tapped.
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('the progress toggle', () {
    testWidgets('starts on the doing side', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.text('Sin registro'), findsOneWidget);
    });

    testWidgets('shows the figures of the sub-tab it was flipped on', (
      tester,
    ) async {
      await pumpScreen(tester);

      await toggleProgress(tester);

      expect(find.text('PROMEDIO'), findsOneWidget);
      expect(find.text('NOCHES ÓPTIMAS'), findsOneWidget);
    });

    testWidgets('applies to the selected sub-tab, not to the section', (
      tester,
    ) async {
      await pumpScreen(tester);
      await toggleProgress(tester);

      await openTab(tester, 'Alimentación');

      // Alimentación was never flipped, so it is still on its list.
      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.text('PROMEDIO DIARIO'), findsNothing);
    });

    testWidgets('remembers which side each sub-tab was left on', (
      tester,
    ) async {
      await pumpScreen(tester);
      await toggleProgress(tester);

      await openTab(tester, 'Ejercicio');
      await openTab(tester, 'Sueño');

      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.text('PROMEDIO'), findsOneWidget);
    });

    testWidgets('flips a second sub-tab without disturbing the first', (
      tester,
    ) async {
      await pumpScreen(tester);
      await toggleProgress(tester);

      await openTab(tester, 'Medicación');
      await toggleProgress(tester);

      expect(find.text('CUMPLIMIENTO'), findsOneWidget);

      await openTab(tester, 'Sueño');

      expect(find.text('PROMEDIO'), findsOneWidget);
    });
  });
}
