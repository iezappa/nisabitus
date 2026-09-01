import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/router/app_tab.dart';
import 'package:drift/native.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/widgets/settings_button.dart';
import 'package:nisabitus/features/settings/presentation/settings_providers.dart';
import 'package:nisabitus/features/health/presentation/health_screen.dart';
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

  testWidgets('an ordinary screen still offers a way into settings', (
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
          // Pinned: these assertions read the Spanish copy, and the
          // test binding would otherwise pick the device default.
          locale: Locale('es'),
          home: HealthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsButton), findsOneWidget);
  });
}
