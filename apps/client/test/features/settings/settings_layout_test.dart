import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/widgets/section_label.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
import 'package:nisabitus/features/shared/support_actions.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings follows the shared Zyreth layout: one flat column of sections,
/// each opened by an uppercase [SectionLabel], with the controls sitting
/// directly on the page.
///
/// These are structure tests on purpose. The standard is only a standard if
/// something fails when the screen drifts away from it.
void main() {
  late ProviderContainer container;

  Future<void> pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    // Tall enough that the whole page is built in one pass: a ListView only
    // builds what fits, and these are assertions about the page as a whole.
    tester.view.physicalSize = const Size(1200, 3200);
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
          // Pinned: these assertions read the Spanish copy.
          locale: Locale('es'),
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens every section with an uppercase label, in the standard '
      'order', (tester) async {
    await pumpSettings(tester);

    final labels = tester
        .widgetList<SectionLabel>(find.byType(SectionLabel))
        .map((label) => label.text.toUpperCase())
        .toList();

    // Security is absent because the app has no PIN; the visible tabs are
    // this app's own section, and go before support.
    expect(labels, [
      'APARIENCIA',
      'PERFIL',
      'IDIOMA',
      'PESTAÑAS VISIBLES',
      'TUS DATOS',
      'SOPORTE',
      'ACERCA DE',
    ]);
  });

  testWidgets('prints those labels in uppercase, not merely stores them', (
    tester,
  ) async {
    await pumpSettings(tester);

    final printed = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(SectionLabel),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList();

    expect(printed.first, 'APARIENCIA');
    expect(printed.last, 'ACERCA DE');
  });

  testWidgets('lays the sections out flat — no card boxes the settings in', (
    tester,
  ) async {
    await pumpSettings(tester);

    // The support block is the one deliberate card: it is a paragraph with
    // two buttons, not a list of rows.
    expect(find.byType(SupportProjectsCard), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Card), matching: find.byType(ListTile)),
      findsNothing,
      reason: 'a row inside a card is the grouped layout the standard drops',
    );
  });

  testWidgets('sits every row flush against the page gutter', (tester) async {
    await pumpSettings(tester);

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
    expect(tiles, isNotEmpty);
    for (final tile in tiles) {
      expect(
        tile.contentPadding,
        EdgeInsets.zero,
        reason: 'a flat layout indents nothing: the page gutter is the margin',
      );
    }
  });

  testWidgets('shows the disclaimer itself, not a tile that hides it', (
    tester,
  ) async {
    await pumpSettings(tester);

    final body = find.textContaining('No diagnostica, no interpreta síntomas');
    expect(body, findsOneWidget);
    expect(
      find.ancestor(of: body, matching: find.byType(ListTile)),
      findsNothing,
      reason: 'a notice you have to tap to read is a notice nobody reads',
    );
  });
}
