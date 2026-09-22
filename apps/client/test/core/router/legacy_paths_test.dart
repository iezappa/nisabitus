import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/router/app_router.dart';
import 'package:nisabitus/core/router/app_tab.dart';
import 'package:nisabitus/features/update/presentation/update_providers.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paths that pointed at something the app has since moved.
///
/// A link the user bookmarked or pinned is theirs, and a section moving
/// house is not a reason for it to stop working.
void main() {
  testWidgets('the old meditation path lands on the health section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final router = buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          availableUpdateProvider.overrideWith((ref) async => null),
        ],
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

    router.go('/meditacion');
    await tester.pumpAndSettle();

    expect(
      router.state.uri.path,
      AppTab.health.path,
      reason: 'a bookmark into the old tab should still open the section',
    );
    // And it is really there: the sub-tab it moved into is on screen.
    expect(find.text('Meditación'), findsOneWidget);
  });
}
