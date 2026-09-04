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

import 'dart:async';
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
import 'package:nisabitus/core/widgets/brand_logo.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nisabitus/features/habits/presentation/habits_screen.dart';
import 'package:nisabitus/core/time/weekday.dart';
import 'package:nisabitus/features/discipline/data/drift_discipline_repository.dart';
import 'package:nisabitus/features/discipline/domain/discipline_repository.dart';
import 'package:nisabitus/features/discipline/presentation/widgets/discipline_dialog.dart';
import 'package:nisabitus/features/exercise/data/drift_exercise_repository.dart';
import 'package:nisabitus/features/exercise/domain/exercise_repository.dart';
import 'package:nisabitus/features/exercise/presentation/exercise_view.dart';
import 'package:nisabitus/features/exercise/domain/scheduled_exercise.dart';
import 'package:nisabitus/features/exercise/presentation/widgets/scheduled_exercise_dialog.dart';
import 'package:nisabitus/features/health/presentation/health_screen.dart';
import 'package:nisabitus/features/hydration/data/drift_hydration_repository.dart';
import 'package:nisabitus/features/hydration/presentation/hydration_view.dart';
import 'package:nisabitus/features/journal/presentation/journal_screen.dart';
import 'package:nisabitus/features/meditation/data/drift_meditation_repository.dart';
import 'package:nisabitus/features/meditation/domain/meditation_repository.dart';
import 'package:nisabitus/features/meditation/presentation/meditation_screen.dart';
import 'package:nisabitus/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
import 'package:nisabitus/features/todo/presentation/todo_screen.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';
import 'package:nisabitus/features/settings/presentation/widgets/tutorial_dialog.dart';
import 'package:nisabitus/features/exercise/presentation/widgets/exercise_form_dialog.dart';
import 'package:nisabitus/features/habits/presentation/widgets/habit_form_dialog.dart';
import 'package:nisabitus/features/medication/presentation/widgets/medication_form_dialog.dart';
import 'package:nisabitus/features/nutrition/data/drift_nutrition_repository.dart';
import 'package:nisabitus/features/nutrition/domain/meal.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition_repository.dart';
import 'package:nisabitus/features/nutrition/presentation/nutrition_view.dart';
import 'package:nisabitus/features/nutrition/presentation/widgets/food_form_dialog.dart';
import 'package:nisabitus/features/nutrition/presentation/widgets/food_database_dialog.dart';
import 'package:nisabitus/features/release_notes/presentation/release_notes_providers.dart';
import 'package:nisabitus/features/release_notes/presentation/widgets/release_notes_dialog.dart';
import 'package:nisabitus/features/streaks/domain/streak.dart';
import 'package:nisabitus/features/streaks/presentation/widgets/streak_editor_dialog.dart';
import 'package:nisabitus/features/todo/presentation/widgets/task_dialog.dart';
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
        assetBundleProvider.overrideWithValue(_ShippedAssets()),
        todayProvider.overrideWithValue(wednesday),
        selectedDayProvider.overrideWith((ref) => wednesday),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  /// Puts [home] on screen at [surface], in the language and brightness asked
  /// for, and leaves it there for the caller to photograph.
  Future<void> mount(
    WidgetTester tester,
    Widget home, {
    required Size surface,
    required Locale locale,
    required Brightness brightness,
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
          locale: locale,
          theme: brightness == Brightness.dark
              ? AppTheme.dark(AccentColor.forest)
              : AppTheme.light(AccentColor.forest),
          debugShowCheckedModeBanner: false,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // An asset image decodes asynchronously and a widget test drives fake
    // async, so without this the frame is photographed before the picture
    // exists. Done for every shot rather than only the ones that show the
    // mark: the image cache is shared, so precaching in one test would make
    // a later golden depend on which test happened to run first.
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/logo.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    Size surface = const Size(1000, 1400),
    Locale locale = spanish,
    Brightness brightness = Brightness.light,
  }) async {
    await mount(
      tester,
      screen,
      surface: surface,
      locale: locale,
      brightness: brightness,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  /// Photographs a dialog rather than a screen.
  ///
  /// The host underneath is a bare `Scaffold` on purpose: what is being looked
  /// at is the dialog, and putting a real screen behind it would make every
  /// one of these goldens fail whenever that screen changed.
  Future<void> shootDialog(
    WidgetTester tester,
    String name,
    Future<void> Function(BuildContext context) open, {
    Size surface = const Size(700, 900),
    Locale locale = spanish,
    Brightness brightness = Brightness.light,
    Future<void> Function()? after,
  }) async {
    late BuildContext hostContext;

    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
      surface: surface,
      locale: locale,
      brightness: brightness,
    );

    // Not awaited: the future only completes when the dialog is dismissed,
    // and dismissing it is the one thing this test must not do.
    unawaited(open(hostContext));
    await tester.pumpAndSettle();

    // Anything the picture needs done to the dialog once it is up. It runs
    // here rather than inside [open], because [open] is deliberately not
    // awaited and two un-nested guarded calls conflict.
    if (after != null) {
      await after();
      await tester.pumpAndSettle();
    }

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

  // The mark on the surface it actually sits on, in both themes. A logo
  // painted the same colour as the panel behind it is not a subtle logo, it
  // is an absent one — and nothing else in this suite would notice.
  for (final brightness in Brightness.values) {
    testWidgets('the brand mark on ${brightness.name}', (tester) async {
      await shoot(
        tester,
        'brand_logo_${brightness.name}',
        Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).navigationRailTheme.backgroundColor!,
            child: const Center(child: BrandLogo(color: Colors.white)),
          ),
        ),
        surface: const Size(240, 160),
        brightness: brightness,
      );
    });
  }

  testWidgets('training', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'training', const Scaffold(body: ExerciseView()));
  });

  testWidgets('meditation', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'meditation', const MeditationScreen());
  });

  testWidgets('hydration', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'hydration', const Scaffold(body: HydrationView()));
  });

  testWidgets('nutrition', (tester) async {
    await seed(db, wednesday);
    await shoot(tester, 'nutrition', const Scaffold(body: NutritionView()));
  });

  testWidgets('settings', (tester) async {
    await shoot(tester, 'settings', const SettingsScreen());
  });

  // The dark theme is not the light one with the colours flipped: it has its
  // own surfaces and its own contrast, and nothing had ever looked at it.
  group('dark', () {
    testWidgets('dashboard', (tester) async {
      await seed(db, wednesday);
      await shoot(
        tester,
        'dashboard_dark',
        const DashboardScreen(),
        brightness: Brightness.dark,
      );
    });

    testWidgets('health', (tester) async {
      await seed(db, wednesday);
      await shoot(
        tester,
        'health_dark',
        const HealthScreen(),
        brightness: Brightness.dark,
      );
    });

    testWidgets('settings', (tester) async {
      await shoot(
        tester,
        'settings_dark',
        const SettingsScreen(),
        brightness: Brightness.dark,
      );
    });
  });

  // English is half the copy this app ships and none of it had been seen. A
  // translation that overflows its row only shows up in a picture.
  group('english', () {
    testWidgets('dashboard', (tester) async {
      await seed(db, wednesday);
      await shoot(
        tester,
        'dashboard_en',
        const DashboardScreen(),
        locale: english,
      );
    });

    testWidgets('settings', (tester) async {
      await shoot(
        tester,
        'settings_en',
        const SettingsScreen(),
        locale: english,
      );
    });
  });

  // A phone is the narrowest thing the app has to survive, and every screen
  // above was photographed on a window no phone has.
  group('phone', () {
    testWidgets('dashboard', (tester) async {
      await seed(db, wednesday);
      await shoot(
        tester,
        'dashboard_phone',
        const DashboardScreen(),
        surface: phone,
      );
    });

    testWidgets('habits', (tester) async {
      await seed(db, wednesday);
      await shoot(tester, 'habits_phone', const HabitsScreen(), surface: phone);
    });

    testWidgets('todo', (tester) async {
      await seed(db, wednesday);
      await shoot(tester, 'todo_phone', const TodoScreen(), surface: phone);
    });

    testWidgets('settings', (tester) async {
      await shoot(
        tester,
        'settings_phone',
        const SettingsScreen(),
        surface: phone,
      );
    });
  });

  // Every dialog the app can open. These are where the forms live, so they
  // hold more layout per pixel than the screens that launch them.
  group('dialogs', () {
    testWidgets('new habit', (tester) async {
      await shootDialog(tester, 'dialog_habit', showHabitForm);
    });

    testWidgets('new food entry', (tester) async {
      // The meal is passed in rather than read off the clock, or this
      // photograph comes out different depending on the hour it was taken.
      await shootDialog(
        tester,
        'dialog_food',
        (context) => showFoodForm(context, initialMeal: Meal.breakfast),
      );
    });

    testWidgets('the food database', (tester) async {
      // The seed is Dart source rather than a bundled asset on purpose:
      // `rootBundle` has nothing behind it in a widget test, so a dialog that
      // loaded its catalogue from an asset would photograph as a spinner.
      await seed(db, wednesday);
      await shootDialog(tester, 'dialog_food_database', showFoodDatabase);
    });

    testWidgets('writing down a food of your own', (tester) async {
      await shootDialog(
        tester,
        'dialog_food_definition',
        showFoodDefinitionForm,
      );
    });

    testWidgets('new exercise', (tester) async {
      await shootDialog(tester, 'dialog_exercise', showExerciseForm);
    });

    testWidgets('an exercise for the day', (tester) async {
      await seed(db, wednesday);
      final catalogue = await DriftExerciseRepository(db).exercises();
      await shootDialog(
        tester,
        'dialog_scheduled_exercise',
        (context) => showScheduledExerciseForm(
          context,
          catalogue: catalogue,
          day: wednesday,
          // Both ways into the catalogue, because the form is the only place
          // left that lists movements: one writes a new one down, the other
          // corrects the one that is picked.
          onCreateExercise: () async => null,
          onEditExercise: (exercise) async => null,
        ),
        surface: const Size(760, 1000),
      );
    });

    testWidgets('an exercise for the day, repeating', (tester) async {
      // The half of the form the eye actually complained about: the switch,
      // the day chips and the duration.
      await seed(db, wednesday);
      final catalogue = await DriftExerciseRepository(db).exercises();
      await shootDialog(
        tester,
        'dialog_scheduled_exercise_repeat',
        (context) => showScheduledExerciseForm(
          context,
          catalogue: catalogue,
          day: wednesday,
        ),
        surface: const Size(760, 1100),
        after: () => tester.tap(find.byType(SwitchListTile)),
      );
    });

    testWidgets('a discipline', (tester) async {
      await shootDialog(
        tester,
        'dialog_discipline',
        (context) => showDisciplineForm(context, day: wednesday),
        surface: const Size(760, 900),
      );
    });

    testWidgets('ticking one off', (tester) async {
      await seed(db, wednesday);
      final scheduled = await DriftExerciseRepository(db)
          .scheduledFor(wednesday);
      await shootDialog(
        tester,
        'dialog_exercise_done',
        (context) => showCompletionForm(context, scheduled: scheduled.first),
        surface: const Size(700, 700),
      );
    });

    testWidgets('new medication', (tester) async {
      await shootDialog(tester, 'dialog_medication', showMedicationForm);
    });

    testWidgets('task', (tester) async {
      await seed(db, wednesday);
      final project = await db.select(db.projects).getSingle();
      await shootDialog(
        tester,
        'dialog_task',
        (context) => showTaskDialog(context, projectId: project.id),
      );
    });

    testWidgets('streak editor', (tester) async {
      final streak = Streak(
        id: 1,
        name: 'Sin azúcar',
        count: 9,
        maxStreak: 14,
        lastUpdated: wednesday,
      );
      await shootDialog(
        tester,
        'dialog_streak',
        (context) => showStreakEditor(
          context,
          streak: streak,
          today: wednesday,
          onReset: () async {},
          onDelete: () async {},
          onRecordDay: (_) async {},
        ),
      );
    });

    testWidgets('tutorial', (tester) async {
      await shootDialog(tester, 'dialog_tutorial', showTutorial);
    });

    testWidgets('release notes', (tester) async {
      await shootDialog(tester, 'dialog_release_notes', showReleaseNotes);
    });
  });
}

/// A phone, in logical pixels: the narrowest shape the app has to survive.
const phone = Size(390, 844);

const spanish = Locale('es');
const english = Locale('en');

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

  final eaten = [
    ('Avena con banana', '80 g', 320, 9, 58, 6, Meal.breakfast),
    ('Café con leche', '1 taza', 90, 5, 8, 4, Meal.breakfast),
    ('Milanesa con puré', '1 plato', 640, 38, 55, 28, Meal.lunch),
    ('Yogur con nueces', '150 g', 210, 11, 18, 11, Meal.snack),
    ('Ensalada y huevo', '1 plato', 380, 22, 20, 24, Meal.dinner),
  ];
  for (final (name, portion, kcal, protein, carbs, fat, meal) in eaten) {
    await NutritionActionsSeed(db).add(
      today,
      name: name,
      portion: portion,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      meal: meal,
    );
  }

  // A week of training, written down the way the app writes it: one row per
  // exercise per day, repeating.
  final training = DriftExerciseRepository(db);
  final squat = await training.createExercise(
    const ExerciseDraft(
      name: 'Sentadilla',
      muscleGroup: 'Piernas',
      videoUrl: 'https://example.test/sentadilla',
    ),
  );
  final press = await training.createExercise(
    const ExerciseDraft(name: 'Press de banca', muscleGroup: 'Pecho'),
  );
  await training.schedule(
    dayBefore(9),
    ScheduledExerciseDraft(
      exerciseId: squat.id,
      sets: 4,
      reps: 6,
      weightKg: 90,
      comments: 'Bajar hasta paralelo, sin rebote',
    ),
    recurrence: ExerciseRecurrence(
      days: const {Weekday.monday, Weekday.wednesday, Weekday.friday},
      type: RecurrenceType.weeks,
      weeks: 8,
    ),
  );
  await training.schedule(
    today,
    ScheduledExerciseDraft(
      exerciseId: press.id,
      sets: 3,
      reps: 8,
      weightKg: 60,
    ),
  );
  final donePress = (await training.scheduledFor(today)).last;
  await training.complete(
    donePress.id,
    const ExerciseCompletion(rpe: 8, feedback: 'Salió redondo'),
  );

  // A swim, which is measured in time and distance rather than in sets.
  await DriftDisciplineRepository(db).schedule(
    today,
    const DisciplineDraft(
      name: 'Natación',
      durationMinutes: 45,
      distanceKm: 2,
      notes: 'Crol suave, sin apurar',
    ),
  );

  // A fortnight of sitting, with the gaps a real practice has.
  for (var i = 0; i < 12; i++) {
    if (i % 5 == 4) continue;
    await DriftMeditationRepository(db).add(
      dayBefore(i),
      MeditationDraft(
        minutes: i.isEven ? 20 : 10,
        note: i == 0 ? 'Costó arrancar, después salió sola' : null,
      ),
    );
  }

  // A day of water, drunk in glasses the way it actually is.
  for (final millilitres in const [350, 200, 500, 200]) {
    await DriftHydrationRepository(db).addEntry(today, millilitres);
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

/// The assets the app actually ships, read straight off the disk.
///
/// `rootBundle` has nothing behind it in a widget test, so the release notes
/// stay loading forever and their dialog is photographed as a spinner — and
/// a spinner is an animation, so `pumpAndSettle` times out rather than
/// failing on the picture. Reading the real files also means these goldens
/// show the changelog that ships, not a fixture that drifts from it.
class _ShippedAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (!file.existsSync()) throw StateError('Asset not found: $key');

    // Read synchronously: a widget test drives fake async, so a real disk
    // read never completes inside `pumpAndSettle` and the spinner it leaves
    // on screen is an animation that never ends.
    return ByteData.sublistView(file.readAsBytesSync());
  }
}

/// Seeds food through the repository rather than through the tables.
///
/// The catalogue is filled by saving an entry, so writing rows straight into
/// `food_entries` would photograph a day of eating with an empty list of
/// foods behind it — which is not a state the app can actually reach.
class NutritionActionsSeed {
  NutritionActionsSeed(this._db);

  final AppDatabase _db;

  Future<void> add(
    DateTime day, {
    required String name,
    required String portion,
    required int kcal,
    required int protein,
    required int carbs,
    required int fat,
    required Meal meal,
  }) => DriftNutritionRepository(_db).addEntry(
    day,
    FoodDraft(
      name: name,
      portion: portion,
      macros: Macros(calories: kcal, protein: protein, carbs: carbs, fat: fat),
      meal: meal,
    ),
  );
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
