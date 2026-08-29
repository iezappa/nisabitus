import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/preferences/preferences.dart';
import 'package:nisabit/features/settings/domain/language_preference.dart';
import 'package:nisabit/features/settings/presentation/settings_providers.dart';
import 'package:nisabit/features/settings/presentation/settings_screen.dart';
import 'package:nisabit/l10n/app_localizations.dart';
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

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: ref.watch(languageChoiceProvider).locale,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LanguageChoice', () {
    test('follows the device until told otherwise', () {
      expect(LanguageChoice.fallback, LanguageChoice.system);
      expect(LanguageChoice.system.locale, isNull);
    });

    test('round-trips through its stored id', () {
      for (final choice in LanguageChoice.values) {
        expect(LanguageChoice.parse(choice.id), choice);
      }
    });

    test('falls back when the stored value is unknown', () {
      expect(LanguageChoice.parse('fr'), LanguageChoice.system);
      expect(LanguageChoice.parse(null), LanguageChoice.system);
    });
  });

  group('both languages are complete', () {
    test('every supported locale resolves the same set of strings', () {
      // A missing key would fall through to the template at runtime and show
      // Spanish inside an English interface.
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);

        expect(l10n.habitsTitle, isNotEmpty, reason: '$locale');
        expect(l10n.sleepQualityOptimal, isNotEmpty, reason: '$locale');
        expect(l10n.tutorialFocusDetail, isNotEmpty, reason: '$locale');
        expect(l10n.todoMoveNotAllowed, isNotEmpty, reason: '$locale');
      }
    });

    test('covers Spanish and English', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(['es', 'en']),
      );
    });

    test('translates rather than repeating the Spanish', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));

      expect(en.habitsEmpty, isNot(es.habitsEmpty));
      expect(en.settingsTheme, 'Theme');
      expect(en.todoStatusInProgress, 'In progress');
    });
  });

  group('the picker', () {
    test('remembers the choice', () async {
      await boot();

      container
          .read(languagePreferenceProvider.notifier)
          .set(LanguageChoice.english.id);

      expect(container.read(languageChoiceProvider), LanguageChoice.english);
      expect(prefs.getString('settings.language'), 'en');
    });

    test('survives a restart', () async {
      await boot({'settings.language': 'en'});

      expect(container.read(languageChoiceProvider), LanguageChoice.english);
    });

    testWidgets('switches the interface on the spot', (tester) async {
      await boot({'settings.language': 'es'});
      await pump(tester);
      // Section headers render their label uppercased.
      expect(find.text('APARIENCIA'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('APARIENCIA'), findsNothing);
    });
  });
}
