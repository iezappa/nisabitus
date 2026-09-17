import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/legal/presentation/about_links.dart';
import 'package:nisabitus/features/release_notes/presentation/release_notes_providers.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  final opened = <Uri>[];

  Future<void> pump(WidgetTester tester, {bool openerWorks = true}) async {
    opened.clear();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetBundleProvider.overrideWithValue(
            _FakeBundle({
              'assets/legal/privacy_es.md':
                  '# Política\n\nSolo en tu **dispositivo**.',
              'assets/legal/terms_es.md': '# Términos\n\n- Gratuita',
            }),
          ),
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
          home: Scaffold(
            body: ListView(
              children: [
                AboutLinks(
                  opener: (url) async {
                    opened.add(url);
                    return openerWorks;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens the bundled privacy policy inside the app', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Política de privacidad'));
    await tester.pumpAndSettle();

    expect(find.text('Política'), findsWidgets);
    expect(find.text('Solo en tu dispositivo.'), findsOneWidget);
    expect(opened, isEmpty, reason: 'the policy must read offline');
  });

  testWidgets('opens the bundled terms inside the app', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Términos de uso'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gratuita'), findsOneWidget);
  });

  testWidgets('names the developer and opens the issues page to contact', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('iezappa'), findsWidgets);
    await tester.tap(find.text('Contacto'));
    await tester.pumpAndSettle();

    expect(opened, [AboutLinks.contactUrl]);
    expect(
      AboutLinks.contactUrl.toString(),
      'https://github.com/iezappa/nisabitus/issues',
    );
  });

  testWidgets('says so when the contact link cannot be opened', (tester) async {
    await pump(tester, openerWorks: false);

    await tester.tap(find.text('Contacto'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('shows the open source licenses', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Licencias'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final text = _files[key];
    if (text == null) throw FlutterError('No asset $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}
