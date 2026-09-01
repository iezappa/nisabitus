import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/router/app_tab.dart';
import 'package:nisabitus/core/widgets/centered_content.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';
import 'package:nisabitus/features/settings/domain/theme_preference.dart';
import 'package:nisabitus/features/settings/presentation/settings_providers.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
import 'package:nisabitus/features/shared/support_actions.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;

  Future<void> boot([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // Pinned: these assertions read the Spanish copy, and the
          // test binding would otherwise pick the device default.
          locale: Locale('es'),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AccentColor', () {
    test('falls back when the stored value is unknown or absent', () {
      expect(AccentColor.parse('nope'), AccentColor.fallback);
      expect(AccentColor.parse(null), AccentColor.fallback);
    });

    test('round-trips through its stored id', () {
      for (final accent in AccentColor.values) {
        expect(AccentColor.parse(accent.id), accent);
      }
    });

    test('offers a lighter tone for the dark scheme', () {
      for (final accent in AccentColor.values) {
        expect(
          accent.resolve(Brightness.dark),
          isNot(accent.resolve(Brightness.light)),
        );
      }
    });
  });

  group('accent preference', () {
    test('starts on the brand accent', () async {
      await boot();

      expect(container.read(accentColorProvider), AccentColor.forest);
    });

    test('remembers the choice', () async {
      await boot();

      container.read(accentPreferenceProvider.notifier).set(AccentColor.gold.id);

      expect(container.read(accentColorProvider), AccentColor.gold);
      expect(prefs.getString('settings.accent'), 'gold');
    });

    testWidgets('retints the interface when picked', (tester) async {
      await boot();
      await pump(tester, const SettingsScreen());

      await tester.tap(find.byTooltip('Dorado'));
      await tester.pumpAndSettle();

      expect(container.read(accentColorProvider), AccentColor.gold);
    });
  });

  group('tab visibility', () {
    test('shows every tab by default', () async {
      await boot();

      expect(container.read(visibleTabsProvider), AppTab.values);
    });

    test('hides a tab', () async {
      await boot();

      container
          .read(tabVisibilityActionsProvider)
          .setVisible(AppTab.todo, visible: false);

      expect(container.read(visibleTabsProvider), isNot(contains(AppTab.todo)));
    });

    test('refuses to hide the last one standing', () async {
      await boot();
      final actions = container.read(tabVisibilityActionsProvider);
      for (final tab in AppTab.values.skip(1)) {
        actions.setVisible(tab, visible: false);
      }

      actions.setVisible(AppTab.values.first, visible: false);

      expect(container.read(visibleTabsProvider), hasLength(1));
    });

    test('repairs a stored set that would leave nothing visible', () async {
      await boot({'settings.visibleTabs': <String>[]});

      expect(container.read(visibleTabsProvider), [AppTab.dashboard]);
    });

    test('keeps the tabs in their declared order', () async {
      await boot({
        'settings.visibleTabs': [AppTab.todo.name, AppTab.habits.name],
      });

      expect(container.read(visibleTabsProvider), [AppTab.habits, AppTab.todo]);
    });
  });

  group('support links', () {
    testWidgets('opens Cafecito externally', (tester) async {
      await boot();
      Uri? opened;

      await pump(
        tester,
        Scaffold(
          body: SupportProjectsCard(
            opener: (url) async {
              opened = url;
              return true;
            },
          ),
        ),
      );
      await tester.tap(find.text('Cafecito'));
      await tester.pumpAndSettle();

      expect(opened, SupportProjectsCard.cafecito);
    });

    testWidgets('shows both platforms side by side, never guessing', (
      tester,
    ) async {
      await boot();
      await pump(tester, const Scaffold(body: SupportProjectsCard()));

      expect(find.text('Cafecito'), findsOneWidget);
      expect(find.text('Patreon'), findsOneWidget);
    });

    testWidgets('warns quietly when the link will not open', (tester) async {
      await boot();

      await pump(
        tester,
        Scaffold(body: SupportProjectsCard(opener: (_) async => false)),
      );
      await tester.tap(find.text('Patreon'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo abrir el enlace'), findsOneWidget);
    });

    testWidgets('survives an opener that throws', (tester) async {
      await boot();

      await pump(
        tester,
        Scaffold(
          body: SupportProjectsCard(
            opener: (_) async => throw Exception('no browser'),
          ),
        ),
      );
      await tester.tap(find.text('Patreon'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo abrir el enlace'), findsOneWidget);
    });
  });

  group('onboarding', () {
    test('is pending on a fresh install', () async {
      await boot();

      expect(container.read(onboardingDoneProvider), isFalse);
    });

    test('stays done once completed', () async {
      await boot();

      container.read(onboardingDoneProvider.notifier).set(true);

      expect(prefs.getBool('settings.onboardingDone'), isTrue);
    });

    test('remembers the profile name', () async {
      await boot();

      container.read(profileNameProvider.notifier).set('Zeke');

      expect(container.read(profileNameProvider), 'Zeke');
    });
  });

  group('theme choice', () {
    test('follows the system until told otherwise', () async {
      await boot();

      expect(container.read(themeChoiceProvider), ThemeChoice.system);
      expect(container.read(themeChoiceProvider).mode, ThemeMode.system);
    });

    test('round-trips through its stored id', () {
      for (final choice in ThemeChoice.values) {
        expect(ThemeChoice.parse(choice.id), choice);
      }
    });

    test('falls back when the stored value is unknown', () {
      expect(ThemeChoice.parse('sepia'), ThemeChoice.system);
      expect(ThemeChoice.parse(null), ThemeChoice.system);
    });

    test('remembers being pinned to dark', () async {
      await boot();

      container.read(themePreferenceProvider.notifier).set(ThemeChoice.dark.id);

      expect(container.read(themeChoiceProvider).mode, ThemeMode.dark);
      expect(prefs.getString('settings.theme'), 'dark');
    });

    test('survives a restart', () async {
      await boot({'settings.theme': 'dark'});

      expect(container.read(themeChoiceProvider), ThemeChoice.dark);
    });

    testWidgets('is switched from the settings screen', (tester) async {
      await boot();
      await pump(tester, const SettingsScreen());

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(container.read(themeChoiceProvider), ThemeChoice.dark);
    });
  });

  group('layout', () {
    testWidgets('keeps its content at a readable width on a wide window', (
      tester,
    ) async {
      await boot();
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
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
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(CenteredContent)).width;
      final inner = tester.getSize(
        find.descendant(
          of: find.byType(CenteredContent),
          matching: find.byType(ListView),
        ),
      );

      expect(width, 1600, reason: 'the wrapper spans the window');
      expect(
        inner.width,
        lessThanOrEqualTo(640),
        reason: 'the content itself stays narrow',
      );
    });

    testWidgets('still fills a narrow window edge to edge', (tester) async {
      await boot();
      await tester.binding.setSurfaceSize(const Size(420, 1200));
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
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inner = tester.getSize(
        find.descendant(
          of: find.byType(CenteredContent),
          matching: find.byType(ListView),
        ),
      );

      expect(inner.width, 420);
    });
  });
}
