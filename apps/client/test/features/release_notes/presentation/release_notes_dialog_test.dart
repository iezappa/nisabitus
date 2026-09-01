import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/release_notes/presentation/release_notes_providers.dart';
import 'package:nisabitus/features/release_notes/presentation/widgets/release_notes_dialog.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  String changelog() => jsonEncode({
    'releases': [
      {
        'version': '1.0.0',
        'date': '2026-01-10',
        'highlights': ['Lo del principio'],
      },
      {
        'version': '1.1.0',
        'date': '2026-05-20',
        'highlights': ['Lo del medio'],
      },
      {
        'version': '1.2.0',
        'date': '2026-08-30',
        'highlights': ['Lo más nuevo'],
      },
    ],
  });

  Future<void> start({String? lastSeen}) async {
    SharedPreferences.setMockInitialValues({
      'releaseNotes.lastSeenVersion': ?lastSeen,
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        assetBundleProvider.overrideWithValue(_FakeBundle(changelog())),
      ],
    );
    addTearDown(container.dispose);
  }

  Future<void> open(WidgetTester tester, {bool unseenOnly = false}) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          // Pinned: these assertions read the Spanish copy.
          locale: const Locale('es'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showReleaseNotes(context, unseenOnly: unseenOnly),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  group('opened from settings', () {
    testWidgets('shows the whole history, newest first', (tester) async {
      await start();
      await open(tester);

      expect(find.text('Lo más nuevo'), findsOneWidget);
      expect(find.text('Lo del medio'), findsOneWidget);
      expect(find.text('Lo del principio'), findsOneWidget);
    });

    testWidgets('names the version of each release', (tester) async {
      await start();
      await open(tester);

      expect(find.text('Versión 1.2.0'), findsOneWidget);
      expect(find.text('Versión 1.0.0'), findsOneWidget);
    });
  });

  group('opened after an update', () {
    testWidgets('shows only what came after the version last seen', (
      tester,
    ) async {
      await start(lastSeen: '1.0.0');
      await open(tester, unseenOnly: true);

      expect(find.text('Lo más nuevo'), findsOneWidget);
      expect(find.text('Lo del medio'), findsOneWidget);
      expect(find.text('Lo del principio'), findsNothing);
    });
  });

  group('remembering', () {
    testWidgets('stamps the newest version once the dialog is closed', (
      tester,
    ) async {
      await start(lastSeen: '1.0.0');
      await open(tester, unseenOnly: true);

      expect(container.read(lastSeenVersionProvider), '1.0.0');

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(container.read(lastSeenVersionProvider), '1.2.0');
    });

    testWidgets('stamps it when dismissed by the barrier too', (tester) async {
      // Dismissing is not "I did not read it": showing it again on every
      // launch would be nagging, not informing.
      await start(lastSeen: '1.0.0');
      await open(tester, unseenOnly: true);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(container.read(lastSeenVersionProvider), '1.2.0');
    });

    testWidgets('stamps it when the whole history is read from settings', (
      tester,
    ) async {
      await start();
      await open(tester);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(container.read(lastSeenVersionProvider), '1.2.0');
    });
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._changelog);

  final String _changelog;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(_changelog)));
}
