import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/settings/presentation/settings_providers.dart';
import 'package:nisabitus/features/settings/presentation/widgets/tutorial_dialog.dart';
import 'package:nisabitus/features/shared/support_actions.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  });

  Future<void> open(WidgetTester tester, {bool onboarding = false}) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showTutorial(context, onboarding: onboarding),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
  }

  group('the page counter', () {
    testWidgets('says which slide of how many is showing', (tester) async {
      await open(tester);

      expect(find.text('1 de 4'), findsOneWidget);
    });

    testWidgets('follows the slides forward and back', (tester) async {
      await open(tester);

      await next(tester);
      expect(find.text('2 de 4'), findsOneWidget);

      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 4'), findsOneWidget);
    });

    testWidgets('counts the two extra slides during onboarding', (
      tester,
    ) async {
      await open(tester, onboarding: true);

      expect(find.text('1 de 6'), findsOneWidget);
    });
  });

  group('the support buttons', () {
    testWidgets('are the same kind of button, not one styled above the other', (
      tester,
    ) async {
      await open(tester);

      // Both are filled: showing one as primary and the other as secondary
      // would be the app choosing a platform for the user.
      final filled = tester.widgetList<FilledButton>(
        find.descendant(
          of: find.byType(SupportProjectsCard),
          matching: find.byType(FilledButton),
        ),
      );

      expect(filled, hasLength(2));
    });

    testWidgets('appear on the opening slide, as the stack document asks', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Cafecito'), findsOneWidget);
      expect(find.text('Patreon'), findsOneWidget);
    });
  });

  group('the slides', () {
    testWidgets('carry a lead line and a paragraph under the title', (
      tester,
    ) async {
      await open(tester);
      await next(tester);

      expect(find.text('Sostener, no arrancar.'), findsOneWidget);
      expect(find.textContaining('Las rachas cuentan aparte'), findsOneWidget);
    });

    testWidgets('centre their text', (tester) async {
      await open(tester);
      await next(tester);

      final lead = tester.widget<Text>(find.text('Sostener, no arrancar.'));
      expect(lead.textAlign, TextAlign.center);
    });
  });

  group('finishing', () {
    testWidgets('offers to skip only outside onboarding', (tester) async {
      await open(tester);
      expect(find.text('Saltar'), findsOneWidget);

      await tester.tap(find.text('Saltar'));
      await tester.pumpAndSettle();
      expect(find.text('Empezar'), findsNothing);
    });

    testWidgets('cannot be skipped during onboarding', (tester) async {
      await open(tester, onboarding: true);

      expect(find.text('Saltar'), findsNothing);
    });

    testWidgets('remembers the name and marks onboarding done', (tester) async {
      await open(tester, onboarding: true);
      for (var i = 0; i < 4; i++) {
        await next(tester);
      }

      await tester.enterText(find.byType(TextField), 'Zeke');
      await next(tester);
      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();

      expect(container.read(profileNameProvider), 'Zeke');
      expect(container.read(onboardingDoneProvider), isTrue);
    });
  });
}
