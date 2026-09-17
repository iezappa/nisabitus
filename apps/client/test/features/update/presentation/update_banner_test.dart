import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';
import 'package:nisabitus/features/update/domain/update_info.dart';
import 'package:nisabitus/features/update/presentation/update_banner.dart';
import 'package:nisabitus/features/update/presentation/update_providers.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService implements UpdateService {
  _FakeService(this.info);
  final UpdateInfo? info;
  @override
  Future<UpdateInfo?> check() async => info;
}

void main() {
  UpdateInfo newer({bool schemaChange = false, AppVersion? min}) => UpdateInfo(
    latest: const AppVersion(1, 3, 0),
    url: Uri.parse('https://example.org'),
    schemaChange: schemaChange,
    minSupportedVersion: min,
  );

  final applied = <UpdateInfo>[];

  Future<void> pump(WidgetTester tester, UpdateInfo? info) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    applied.clear();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          updateServiceProvider.overrideWithValue(_FakeService(info)),
          installedVersionProvider.overrideWith(
            (ref) async => const AppVersion(1, 2, 0),
          ),
          applyUpdateProvider.overrideWithValue((info) async {
            applied.add(info);
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(body: UpdateBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the banner for a newer version', (tester) async {
    await pump(tester, newer());
    expect(find.text('A new version is available'), findsOneWidget);
    expect(find.textContaining('1.3.0'), findsOneWidget);
    expect(find.textContaining('Export a backup'), findsNothing);
  });

  testWidgets('recommends a backup when the schema changes', (tester) async {
    await pump(tester, newer(schemaChange: true));
    expect(find.textContaining('Export a backup before updating'), findsOne);
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('warns when the installed version is too old', (tester) async {
    await pump(tester, newer(min: const AppVersion(1, 2, 5)));
    expect(find.textContaining('too old to update directly'), findsOneWidget);
  });

  testWidgets('shows nothing when there is no update', (tester) async {
    await pump(tester, null);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('the main action applies the update', (tester) async {
    await pump(tester, newer());
    // Download off the web, Update on it: the main action either way.
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(applied, hasLength(1));
  });

  testWidgets('dismissing hides it until the next version', (tester) async {
    await pump(tester, newer());
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });
}
