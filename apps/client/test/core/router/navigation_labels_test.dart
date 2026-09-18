import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/router/app_router.dart';
import 'package:nisabitus/core/router/app_tab.dart';
import 'package:nisabitus/core/theme/app_theme.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';
import 'package:nisabitus/features/update/presentation/update_providers.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/real_fonts.dart';

/// Phone widths from the browser run where "Pomodo/ro" and "Meditati/on"
/// broke across two lines, with every tab visible.
void main() {
  // Ahem's square glyphs would say nothing about how Roboto fits.
  setUpAll(loadRealFonts);

  for (final width in [360.0, 412.0]) {
    for (final locale in const [Locale('en'), Locale('es')]) {
      for (final selected in AppTab.values) {
        testWidgets(
          'no tab label wraps at ${width.toInt()}px in ${locale.languageCode} '
          'with ${selected.name} open',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            final db = AppDatabase.forTesting(NativeDatabase.memory());
            addTearDown(db.close);
            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  databaseProvider.overrideWithValue(db),
                  sharedPreferencesProvider.overrideWithValue(prefs),
                  availableUpdateProvider.overrideWith((ref) async => null),
                ],
                child: MaterialApp(
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: locale,
                  theme: AppTheme.light(AccentColor.forest),
                  home: AppShell(
                    location: selected.path,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final labels = tester.renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.byType(RichText),
              ),
            );
            expect(labels.length, greaterThanOrEqualTo(AppTab.values.length));
            for (final label in labels) {
              // One line of this text, unconstrained, is the yardstick: a
              // paragraph any taller than that has broken onto a second line.
              final oneLine = TextPainter(
                text: label.text,
                textDirection: label.textDirection,
                textScaler: label.textScaler,
              )..layout();
              addTearDown(oneLine.dispose);
              expect(
                label.size.height,
                lessThan(oneLine.height * 1.5),
                reason: '"${label.text.toPlainText()}" wrapped',
              );
            }
          },
        );
      }
    }
  }
}
