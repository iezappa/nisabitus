// Accessibility guidelines on the main screens and settings, in both themes
// (CUMPLIMIENTO.md 1.4, STACK-APPS-DINAMICAS.md 2.2 and 7).
//
// Tap targets of 48x48 (Android) and 44x44 (iOS), a label on everything
// tappable, and text contrast of 4.5:1. A screen that regresses on any of
// them fails here rather than in someone's hands.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/theme/app_theme.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nisabitus/features/habits/presentation/habits_screen.dart';
import 'package:nisabitus/features/health/presentation/health_screen.dart';
import 'package:nisabitus/features/journal/presentation/journal_screen.dart';
import 'package:nisabitus/features/meditation/presentation/meditation_view.dart';
import 'package:nisabitus/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
import 'package:nisabitus/features/todo/presentation/todo_screen.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final wednesday = DateTime(2026, 3, 11);

  final screens = <String, Widget>{
    'settings': const SettingsScreen(),
    'dashboard': const DashboardScreen(),
    'habits': const HabitsScreen(),
    'health': const HealthScreen(),
    'journal': const JournalScreen(),
    'pomodoro': const PomodoroScreen(),
    'todo': const TodoScreen(),
    // A sub-tab of Salud, checked on its own: a TabBarView builds the tab
    // it is showing, so the health entry above never reaches this one.
    'meditation': const Scaffold(body: MeditationView()),
  };

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$name meets the accessibility guidelines '
          '(${brightness.name})', (tester) async {
        final handle = tester.ensureSemantics();
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              sharedPreferencesProvider.overrideWithValue(prefs),
              todayProvider.overrideWithValue(wednesday),
              selectedDayProvider.overrideWith((ref) => wednesday),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('es'),
              theme: brightness == Brightness.dark
                  ? AppTheme.dark(AccentColor.forest)
                  : AppTheme.light(AccentColor.forest),
              home: screen,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        // Let the drift streams close before the database does.
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      });
    }
  }
}
