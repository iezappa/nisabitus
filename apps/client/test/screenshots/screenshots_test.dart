// Renders the app's screens to PNG files so they can actually be looked at.
//
//   flutter test test/screenshots --update-goldens
//
// The images land in `test/screenshots/goldens/`. Run without the flag and
// they become a regression test: a layout that shifts fails here.
//
// Text needs a real font. The test binding ships Ahem, which draws every
// glyph as a filled box — fine for catching a layout that moved, useless for
// looking at a screen. Roboto comes from the Flutter SDK, so these images
// depend on the SDK version; a golden that fails after an upgrade is worth a
// look before it is regenerated.
@Tags(['screenshots'])
library;

import 'dart:io';

// drift's `Value` wraps the optional columns the seed data sets.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:nisabitus/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
import 'package:nisabitus/features/todo/presentation/todo_screen.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final wednesday = DateTime(2026, 3, 11);

  setUpAll(_loadFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'settings.profileName': 'Zeke'});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        todayProvider.overrideWithValue(wednesday),
        selectedDayProvider.overrideWith((ref) => wednesday),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    Size surface = const Size(1000, 1400),
  }) async {
    // The view, not `setSurfaceSize`: that one resizes the surface the tree
    // is painted on but leaves MediaQuery reporting the default 800x600, so
    // a screen that lays itself out by width — To-Do's sidebar — would be
    // photographed in the wrong shape.
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = surface * 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
          theme: AppTheme.light(AccentColor.forest),
          debugShowCheckedModeBanner: false,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('dashboard', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'dashboard', const DashboardScreen());
  });

  testWidgets('habits', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'habits', const HabitsScreen());
  });

  testWidgets('habits with nothing recorded yet', (tester) async {
    // No seed: this is the first-run shape of the screen, where every
    // section stands on its placeholder rather than on its content.
    await shoot(tester, 'habits_empty', const HabitsScreen());
  });

  testWidgets('health', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'health', const HealthScreen());
  });

  testWidgets('journal', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'journal', const JournalScreen());
  });

  testWidgets('pomodoro', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'pomodoro', const PomodoroScreen());
  });

  testWidgets('todo', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'todo', const TodoScreen());
  });

  testWidgets('todo on a wide window', (tester) async {
    await seed(db, wednesday);
    await shoot(
      tester,
      'todo_wide',
      const TodoScreen(),
      surface: const Size(1600, 1000),
    );
  });

  testWidgets('settings', (tester) async {
    await shoot(tester, 'settings', const SettingsScreen());
  });
}

/// A fortnight of a life, so the screens show what a used app looks like
/// rather than the empty state everyone has already seen.
Future<void> seed(AppDatabase db, DateTime today) async {
  DateTime dayBefore(int days) => today.subtract(Duration(days: days));

  for (final name in const ['Meditar', 'Leer', 'Caminar']) {
    final id = await db
        .into(db.habits)
        .insert(
          HabitsCompanion.insert(
            name: name,
            description: Value('Todos los días, apenas me levanto'),
            category: const Value('Bienestar'),
            frequency: 'DAILY',
            status: 'PENDING',
            createdAt: dayBefore(30),
            scheduledDate: today,
            repeatForever: const Value(true),
          ),
        );
    for (var i = 0; i < 12; i++) {
      if (i % 4 == 3) continue; // a missed day here and there
      await db
          .into(db.habitCompletions)
          .insert(
            HabitCompletionsCompanion.insert(
              habitId: id,
              completionDate: dayBefore(i),
            ),
          );
    }
  }

  for (final (name, count, record) in const [
    ('Sin azúcar', 9, 14),
    ('Gimnasio', 4, 21),
  ]) {
    await db
        .into(db.streaks)
        .insert(
          StreaksCompanion.insert(
            name: name,
            count: Value(count),
            maxStreak: Value(record),
            lastUpdated: today,
          ),
        );
  }

  for (var i = 0; i < 10; i++) {
    await db
        .into(db.sleepLogs)
        .insert(
          SleepLogsCompanion.insert(
            hours: 6.5 + (i % 4) * 0.75,
            date: dayBefore(i),
          ),
        );
  }

  await db
      .into(db.moodEntries)
      .insert(
        MoodEntriesCompanion.insert(
          content:
              'Día tranquilo. Terminé lo que me había propuesto y me '
              'quedó tiempo para leer un rato antes de dormir.',
          date: today,
        ),
      );

  final vitamin = await db
      .into(db.medications)
      .insert(
        MedicationsCompanion.insert(
          name: 'Vitamina D',
          kind: 'SUPPLEMENT',
          dose: const Value('1000 UI'),
          schedule: const Value('Con el desayuno'),
          activeFrom: Value(dayBefore(20)),
        ),
      );
  await db
      .into(db.medicationIntakes)
      .insert(
        MedicationIntakesCompanion.insert(medicationId: vitamin, date: today),
      );

  final project = await db
      .into(db.projects)
      .insert(ProjectsCompanion.insert(name: 'Nisabitus'));
  for (final (title, status, priority) in const [
    ('Escribir los tests de migración', 'DONE', 'HIGH'),
    ('Mirar la UI de una vez', 'IN_PROGRESS', 'HIGH'),
    ('Vigilar las dependencias EOL', 'TODO', 'LOW'),
  ]) {
    await db
        .into(db.todoTasks)
        .insert(
          TodoTasksCompanion.insert(
            title: title,
            status: status,
            priority: priority,
            projectId: project,
            dueDate: Value(dayBefore(-2)),
          ),
        );
  }

  for (var i = 0; i < 6; i++) {
    await db
        .into(db.pomodoroSessions)
        .insert(
          PomodoroSessionsCompanion.insert(
            name: 'Sesión de foco',
            category: const Value('Trabajo'),
            status: 'COMPLETED',
            startedAt: dayBefore(i),
            completedCycles: Value(2 + i % 3),
          ),
        );
  }
}

/// Loads Roboto and the icon font from the Flutter SDK, so the screenshots
/// carry real text and real icons rather than Ahem's boxes.
Future<void> _loadFonts() async {
  final fonts = _materialFontsDirectory();
  if (fonts == null) {
    fail(
      'Could not find the SDK material_fonts directory. '
      'Set FLUTTER_ROOT, or run these through `flutter test`.',
    );
  }

  await _load(fonts, 'Roboto', const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await _load(fonts, 'MaterialIcons', const ['MaterialIcons-Regular.otf']);
}

Future<void> _load(Directory fonts, String family, List<String> faces) async {
  final loader = FontLoader(family);
  for (final face in faces) {
    final file = File('${fonts.path}/$face');
    if (file.existsSync()) {
      loader.addFont(
        file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
  }
  await loader.load();
}

/// The SDK's bundled fonts, looked up the two ways that work in a test run.
Directory? _materialFontsDirectory() {
  const relative = 'bin/cache/artifacts/material_fonts';

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final fromEnvironment = Directory('$root/$relative');
    if (fromEnvironment.existsSync()) return fromEnvironment;
  }

  // The test runs inside flutter_tester, which lives under the same cache.
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.path != directory.parent.path) {
    final candidate = Directory('${directory.path}/$relative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  return null;
}
