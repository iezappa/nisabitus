import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/pomodoro/domain/focus_sound.dart';
import 'package:nisabitus/features/pomodoro/domain/pomodoro_draft.dart';
import 'package:nisabitus/features/pomodoro/presentation/pomodoro_providers.dart';
import 'package:nisabitus/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:nisabitus/features/pomodoro/presentation/widgets/focus_ring.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  /// Wide by default: the two panes are the point.
  Future<void> pumpScreen(
    WidgetTester tester, {
    Size window = const Size(1400, 1600),
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
          locale: Locale('es'),
          home: PomodoroScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> aSession([String name = 'Escribir']) => container
      .read(pomodoroActionsProvider)
      .create(PomodoroDraft(name: name, focusDuration: 25));

  group('the clock', () {
    testWidgets('is locked while nothing is running', (tester) async {
      await pumpScreen(tester);

      expect(find.text(FocusRing.idleTime), findsOneWidget);
      expect(find.text('Sin pomodoro en curso'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('offers its controls but refuses them when locked', (
      tester,
    ) async {
      // Present and dead, rather than absent: buttons that appear when a
      // session is picked would shift everything under them.
      await pumpScreen(tester);

      final play = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.play_arrow),
      );
      expect(play.onPressed, isNull);
    });

    testWidgets('takes the session picked from the history', (tester) async {
      await aSession();
      await pumpScreen(tester);

      await tester.tap(find.text('Escribir'));
      await tester.pumpAndSettle();

      // The clock now counts, and says which phase it is in.
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text(FocusRing.idleTime), findsNothing);
      expect(find.text('FOCO'), findsOneWidget);
      expect(find.text('Escribir'), findsNWidgets(2), reason: 'clock and row');
    });

    testWidgets('runs, and gives the session back when closed', (tester) async {
      await aSession();
      await pumpScreen(tester);
      await tester.tap(find.text('Escribir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sin guardar'));
      await tester.pumpAndSettle();

      expect(find.text(FocusRing.idleTime), findsOneWidget);
      expect(find.text('Escribir'), findsOneWidget, reason: 'still listed');
    });
  });

  group('the history', () {
    testWidgets('sits beside the clock on a wide window', (tester) async {
      await aSession();
      await pumpScreen(tester);

      final clock = tester.getCenter(find.text(FocusRing.idleTime));
      final row = tester.getCenter(find.text('Escribir'));
      expect(row.dx, greaterThan(clock.dx), reason: 'history on the right');
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('stacks under the clock on a narrow one', (tester) async {
      await aSession();
      await pumpScreen(tester, window: const Size(420, 2000));

      final clock = tester.getCenter(find.text(FocusRing.idleTime));
      final row = tester.getCenter(find.text('Escribir'));
      expect(row.dy, greaterThan(clock.dy), reason: 'history underneath');
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('creates a session from its own button', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Nueva sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Leer');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Leer'), findsOneWidget);
    });

    testWidgets('marks the session the clock is running', (tester) async {
      await aSession();
      await pumpScreen(tester);

      // The row's own card: once the clock is running, the session's name
      // is on screen twice.
      Color? cardColour() => tester
          .widget<Card>(
            find
                .ancestor(
                  of: find.byType(ListTile),
                  matching: find.byType(Card),
                )
                .first,
          )
          .color;

      expect(cardColour(), isNull);
      await tester.tap(find.text('Escribir'));
      await tester.pumpAndSettle();

      expect(cardColour(), isNotNull);
    });
  });

  group('the sound', () {
    Future<void> openForm(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Agregar sonido'));
      await tester.pumpAndSettle();
    }

    testWidgets('starts silent, with an empty library', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Todavía no agregaste ningún sonido.'), findsOneWidget);
    });

    testWidgets('is added from a link and chosen straight away', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Lluvia');
      await tester.enterText(
        find.byType(TextFormField).last,
        'https://www.youtube.com/watch?v=abcdefghijk',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      final sounds = await container.read(focusSoundRepositoryProvider).list();
      expect(sounds.single.name, 'Lluvia');
      expect(container.read(chosenSoundProvider)?.name, 'Lluvia');
    });

    testWidgets('refuses a link it could not play', (tester) async {
      // Said at the moment it is pasted, not in the middle of a session.
      await pumpScreen(tester);
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Ruido');
      await tester.enterText(find.byType(TextFormField).last, 'no es un link');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ese link no se puede reproducir acá adentro.'),
        findsOneWidget,
      );
      expect(
        await container.read(focusSoundRepositoryProvider).list(),
        isEmpty,
      );
    });

    testWidgets('always offers the way out to the browser', (tester) async {
      // There is no event that says a frame was refused — an old browser,
      // a video whose channel forbids embedding — so the escape is on
      // screen from the start rather than after it would have helped.
      final sound = await container
          .read(focusSoundRepositoryProvider)
          .add(
            FocusSoundDraft(
              name: 'Lluvia',
              url: 'https://youtu.be/abcdefghijk',
            ),
          );
      container.read(focusSoundActionsProvider).choose(sound.id);
      await pumpScreen(tester);

      expect(find.widgetWithText(TextButton, 'Abrir afuera'), findsOneWidget);
    });

    testWidgets('forgets a sound that is deleted', (tester) async {
      final sound = await container
          .read(focusSoundRepositoryProvider)
          .add(
            FocusSoundDraft(
              name: 'Lluvia',
              url: 'https://youtu.be/abcdefghijk',
            ),
          );
      container.read(focusSoundActionsProvider).choose(sound.id);
      await pumpScreen(tester);

      await container.read(focusSoundActionsProvider).delete(sound.id);
      await tester.pumpAndSettle();

      expect(container.read(chosenSoundProvider), isNull);
      expect(find.text('Todavía no agregaste ningún sonido.'), findsOneWidget);
    });
  });
}
