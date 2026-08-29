import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/preferences/preferences.dart';
import 'package:nisabit/core/router/app_tab.dart';
import 'package:nisabit/core/widgets/coming_soon_screen.dart';
import 'package:nisabit/core/widgets/settings_button.dart';
import 'package:nisabit/features/settings/presentation/settings_providers.dart';
import 'package:nisabit/l10n/app_localizations.dart';
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

  test('settings is not one of the hideable tabs', () {
    // The whole point: a tab can be hidden, and hiding the screen that
    // unhides tabs would leave the user with no way back in.
    expect(
      AppTab.values.map((tab) => tab.name),
      isNot(contains('settings')),
    );
  });

  test('every hideable tab can still be hidden down to the last one', () {
    final actions = container.read(tabVisibilityActionsProvider);
    for (final tab in AppTab.values) {
      actions.setVisible(tab, visible: false);
    }

    expect(container.read(visibleTabsProvider), hasLength(1));
  });

  testWidgets('a screen with nothing in it still offers a way into settings', (
    tester,
  ) async {
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
          home: ComingSoonScreen(title: 'Panel'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsButton), findsOneWidget);
  });
}
