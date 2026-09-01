import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/release_notes/presentation/release_notes_providers.dart';
import 'package:nisabitus/features/release_notes/presentation/widgets/release_notes_tile.dart';
import 'package:nisabitus/features/settings/presentation/settings_screen.dart';
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
        'version': '1.2.0',
        'date': '2026-08-30',
        'highlights': ['Lo más nuevo'],
      },
    ],
  });

  Future<void> boot({String? lastSeen}) async {
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

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings offers the release notes', (tester) async {
    await boot(lastSeen: '1.2.0');
    await pump(tester);

    expect(find.text('Novedades'), findsOneWidget);
  });

  testWidgets('marks the row while something is unread', (tester) async {
    await boot(lastSeen: '1.0.0');
    await pump(tester);

    expect(find.byKey(ReleaseNotesTile.unreadMark), findsOneWidget);
  });

  testWidgets('drops the mark once everything has been seen', (tester) async {
    await boot(lastSeen: '1.2.0');
    await pump(tester);

    expect(find.byKey(ReleaseNotesTile.unreadMark), findsNothing);
  });

  testWidgets('opening the row shows the history and clears the mark', (
    tester,
  ) async {
    await boot(lastSeen: '1.0.0');
    await pump(tester);

    await tester.tap(find.text('Novedades'));
    await tester.pumpAndSettle();
    expect(find.text('Lo del principio'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(container.read(lastSeenVersionProvider), '1.2.0');
    expect(find.byKey(ReleaseNotesTile.unreadMark), findsNothing);
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._changelog);

  final String _changelog;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(_changelog)));
}
