import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/app/launch_gate.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/release_notes/presentation/release_notes_providers.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  const changelog = {
    'releases': [
      {
        'version': '1.0.0',
        'date': '2026-01-10',
        'highlights': ['Lo del principio'],
      },
      {
        'version': '1.2.0',
        'date': '2026-08-30',
        'highlights': ['Lo más nuevo'],
      },
    ],
  };

  Future<void> boot({
    bool onboarded = true,
    String? lastSeen,
    String source = '',
  }) async {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': onboarded,
      'releaseNotes.lastSeenVersion': ?lastSeen,
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        assetBundleProvider.overrideWithValue(
          _FakeBundle(source.isEmpty ? jsonEncode(changelog) : source),
        ),
      ],
    );
    addTearDown(container.dispose);
  }

  Future<void> launch(WidgetTester tester) async {
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
          home: const LaunchGate(child: Scaffold(body: Text('la app'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the app underneath whatever it decides to open', (
    tester,
  ) async {
    await boot(lastSeen: '1.2.0');
    await launch(tester);

    expect(find.text('la app'), findsOneWidget);
  });

  group('a first run', () {
    testWidgets('opens the tutorial', (tester) async {
      await boot(onboarded: false);
      await launch(tester);

      expect(find.text('1 de 6'), findsOneWidget);
    });

    testWidgets('does not also announce releases the user never used', (
      tester,
    ) async {
      await boot(onboarded: false);
      await launch(tester);

      expect(find.text('Lo del principio'), findsNothing);
    });

    testWidgets('starts the user off up to date', (tester) async {
      // Otherwise the first thing they see after onboarding is a history of
      // versions they were never around for.
      await boot(onboarded: false);
      await launch(tester);

      expect(container.read(lastSeenVersionProvider), '1.2.0');
    });
  });

  group('a launch after an update', () {
    testWidgets('announces only what is new', (tester) async {
      await boot(lastSeen: '1.0.0');
      await launch(tester);

      expect(find.text('Lo más nuevo'), findsOneWidget);
      expect(find.text('Lo del principio'), findsNothing);
    });

    testWidgets('does not open the tutorial again', (tester) async {
      await boot(lastSeen: '1.0.0');
      await launch(tester);

      expect(find.text('1 de 6'), findsNothing);
    });
  });

  group('an ordinary launch', () {
    testWidgets('opens nothing when there is nothing to say', (tester) async {
      await boot(lastSeen: '1.2.0');
      await launch(tester);

      expect(find.text('Lo más nuevo'), findsNothing);
      expect(find.text('1 de 6'), findsNothing);
    });
  });

  group('a broken changelog', () {
    testWidgets('lets the app start rather than failing the launch', (
      tester,
    ) async {
      await boot(lastSeen: '1.0.0', source: 'not json');
      await launch(tester);

      expect(find.text('la app'), findsOneWidget);
      expect(find.text('Lo más nuevo'), findsNothing);
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
