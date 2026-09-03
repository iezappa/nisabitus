// The app driven end to end, on the real thing: its own Drift database on
// disk, its own preferences, its own router. The widget tests build one
// screen with everything faked around it, so nothing there would notice a
// database that fails to open on a real platform, a migration that throws on
// first launch, or a route that no longer resolves.
//
//   flutter test integration_test -d linux
//
// On a headless machine, wrap it: `xvfb-run -a flutter test integration_test
// -d linux`. The Linux shell is a real GTK application and wants a display
// even when nobody is watching.
//
// The same flow runs in a browser through `tool/test_web.sh`, which is the
// only thing in this repository that loads the web build at all.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nisabitus/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Onboarding done, so the launch gate does not open the tutorial over the
    // app; Spanish pinned, so the copy these steps look for is deterministic
    // whatever locale the machine running this happens to have.
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.language': 'es',
      'releaseNotes.lastSeenVersion': '99.0.0',
    });
  });

  testWidgets('a habit written down survives leaving the screen', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    // The app opens on the panel, which is where a launch that broke — a
    // database that will not open, a route that no longer resolves — shows
    // up first.
    expect(find.text('Panel'), findsWidgets);

    await tester.tap(find.text('Hábitos').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final name = 'Meditar ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), name);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await revealInList(tester, find.text(name));

    expect(find.text(name), findsOneWidget);

    // Leave and come back: the row on the way back was read from the
    // database, not from the state the form left behind.
    await tester.tap(find.text('Panel').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hábitos').first);
    await revealInList(tester, find.text(name));

    expect(find.text(name), findsOneWidget);
  });
}

/// Brings [finder] into view, whether it is waiting on the database or just
/// sitting below the fold.
///
/// This test writes to the real database — that is the point of it — so on a
/// machine that has run it before, the habits list already has the habits
/// every earlier run left behind and the newest one is off screen. A ListView
/// does not build what is off screen, so no amount of pumping will ever find
/// it: it has to be scrolled to.
Future<void> revealInList(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder);
  if (finder.evaluate().isNotEmpty) return;

  final list = find.byType(Scrollable).last;
  for (var attempt = 0; attempt < 25 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
}

/// Pumps until [finder] matches something, or until [timeout] runs out.
///
/// `pumpAndSettle` is enough on a native platform, where a write and the
/// stream that reports it back land within the same frame budget. On the web
/// drift lives in a worker and answers over a message channel, so the screen
/// goes quiet — nothing is animating — a good while before the row exists.
/// Settling for quiet and asserting immediately turns that into a flake that
/// only ever fails in a browser.
///
/// Giving up leaves the finder unsatisfied on purpose: the assertion that
/// follows is what reports the failure, and it prints what it was looking for.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);

  do {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  } while (DateTime.now().isBefore(deadline));
}
