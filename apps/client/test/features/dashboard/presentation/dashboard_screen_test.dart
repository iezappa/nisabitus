import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/core/widgets/centered_content.dart';
import 'package:nisabitus/core/widgets/stat_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:nisabitus/core/router/app_tab.dart';
import 'package:nisabitus/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nisabitus/features/settings/presentation/settings_providers.dart';
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

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size surface = const Size(900, 1400),
  }) async {
    await tester.binding.setSurfaceSize(surface);
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
          locale: Locale('es'),
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The panel inside a router, so a shortcut can actually be followed.
  Future<GoRouter> pumpRouted(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: AppTab.dashboard.path,
      routes: [
        GoRoute(
          path: AppTab.dashboard.path,
          builder: (_, _) => const DashboardScreen(),
        ),
        for (final tab in AppTab.values)
          if (tab != AppTab.dashboard)
            GoRoute(
              path: tab.path,
              builder: (_, _) => Scaffold(body: Text('en ${tab.path}')),
            ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  group('the summary tiles', () {
    testWidgets('are the same height, whatever each one has to say', (
      tester,
    ) async {
      // One tile carries a caption and the other does not. Sized to their
      // own content, they end up different heights and centred against each
      // other, which reads as a mistake rather than as a pair.
      await pumpScreen(tester);

      final tiles = tester.widgetList<StatTile>(find.byType(StatTile)).toList();
      expect(tiles, hasLength(2));

      final first = tester.getRect(find.byType(StatTile).first);
      final second = tester.getRect(find.byType(StatTile).last);
      expect(second.top, first.top);
      expect(second.height, first.height);
    });
  });

  group('quick actions', () {
    testWidgets('offers a shortcut to every other tab', (tester) async {
      await pumpScreen(tester);

      expect(find.text('ACCESOS RÁPIDOS'), findsOneWidget);
      for (final label in const [
        'Hábitos',
        'Journal',
        'Salud',
        'Pomodoro',
        'To-Do',
      ]) {
        expect(
          find.widgetWithText(ActionChip, label),
          findsOneWidget,
          reason: 'a shortcut to $label',
        );
      }
    });

    testWidgets('leaves out the panel the user is already on', (tester) async {
      await pumpScreen(tester);

      expect(find.widgetWithText(ActionChip, 'Panel'), findsNothing);
    });

    testWidgets('leaves out a tab the user hid', (tester) async {
      container
          .read(tabVisibilityActionsProvider)
          .setVisible(AppTab.pomodoro, visible: false);

      await pumpScreen(tester);

      expect(find.widgetWithText(ActionChip, 'Pomodoro'), findsNothing);
      expect(find.widgetWithText(ActionChip, 'Journal'), findsOneWidget);
    });

    testWidgets('takes the user there when tapped', (tester) async {
      final router = await pumpRouted(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'Journal'));
      await tester.pumpAndSettle();

      expect(find.text('en ${AppTab.journal.path}'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppTab.journal.path,
      );
    });
  });

  group('reading measure', () {
    testWidgets('keeps its content narrow on a wide window', (tester) async {
      await pumpScreen(tester, surface: const Size(1600, 1400));

      expect(tester.getSize(find.byType(CenteredContent)).width, 1600);
      expect(
        tester.getSize(find.byType(ListView)).width,
        CenteredContent.readingMeasure,
      );
    });

    testWidgets('still fills a narrow window edge to edge', (tester) async {
      await pumpScreen(tester, surface: const Size(420, 1400));

      expect(tester.getSize(find.byType(ListView)).width, 420);
    });
  });
}
