import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/widgets/disclaimer.dart';
import 'package:nisabitus/features/health/presentation/health_screen.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
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
          locale: const Locale('es'),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('in settings', () {
    testWidgets('the notice is stated, not hidden behind an icon', (
      tester,
    ) async {
      await pump(tester, const SettingsScreen());

      expect(find.byType(DisclaimerCard), findsOneWidget);
      expect(
        find.text(
          'Nisabitus registra lo que anotás. No reemplaza a un profesional '
          'de la salud.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the full text opens from the card', (tester) async {
      await pump(tester, const SettingsScreen());

      await tester.tap(find.text('Leer el aviso completo'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No diagnostica, no interpreta síntomas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hablá con un profesional de la salud'),
        findsOneWidget,
      );
    });
  });

  group('in the health section', () {
    testWidgets('a question mark sits next to the data being entered', (
      tester,
    ) async {
      await pump(tester, const HealthScreen());

      expect(find.byType(DisclaimerButton), findsOneWidget);
    });

    testWidgets('it opens the same notice, word for word', (tester) async {
      await pump(tester, const HealthScreen());

      await tester.tap(find.byType(DisclaimerButton));
      await tester.pumpAndSettle();

      // One source of wording, so the two entry points cannot drift apart.
      expect(
        find.text('Esto es un registro, no un consejo médico'),
        findsOneWidget,
      );
      expect(
        find.textContaining('No diagnostica, no interpreta síntomas'),
        findsOneWidget,
      );
    });

    testWidgets('covers every view under the tab', (tester) async {
      await pump(tester, const HealthScreen());

      for (final tab in ['Sueño', 'Alimentación', 'Ejercicio', 'Medicación']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();

        expect(
          find.byType(DisclaimerButton),
          findsOneWidget,
          reason: 'the notice vanished on $tab',
        );
      }
    });
  });
}
