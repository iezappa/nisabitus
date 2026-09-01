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
    await tester.pumpAndSettle();

    expect(find.text(name), findsOneWidget);

    // Leave and come back: the row on the way back was read from the
    // database, not from the state the form left behind.
    await tester.tap(find.text('Panel').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hábitos').first);
    await tester.pumpAndSettle();

    expect(find.text(name), findsOneWidget);
  });
}
