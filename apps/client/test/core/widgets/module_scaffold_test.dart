import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/widgets/centered_content.dart';
import 'package:nisabitus/core/widgets/module_scaffold.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Size surface,
    double? listMaxWidth,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: ModuleScaffold(
          title: 'Módulo',
          listMaxWidth: listMaxWidth ?? CenteredContent.readingMeasure,
          list: const SizedBox.expand(key: ValueKey('list')),
          progress: const SizedBox.expand(key: ValueKey('progress')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Flips the frame from doing to reviewing.
  Future<void> showProgress(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.insights));
    await tester.pumpAndSettle();
  }

  group('reading measure', () {
    testWidgets('keeps the doing side narrow on a wide window', (tester) async {
      await pump(tester, surface: const Size(1600, 1200));

      expect(tester.getSize(find.byType(CenteredContent)).width, 1600);
      expect(
        tester.getSize(find.byKey(const ValueKey('list'))).width,
        CenteredContent.readingMeasure,
      );
    });

    testWidgets('keeps the reviewing side narrow too', (tester) async {
      await pump(tester, surface: const Size(1600, 1200));
      await showProgress(tester);

      expect(
        tester.getSize(find.byKey(const ValueKey('progress'))).width,
        CenteredContent.readingMeasure,
      );
    });

    testWidgets('still fills a narrow window edge to edge', (tester) async {
      await pump(tester, surface: const Size(420, 1200));

      expect(tester.getSize(find.byKey(const ValueKey('list'))).width, 420);
    });

    testWidgets('lets a two-pane module keep the whole window', (tester) async {
      await pump(
        tester,
        surface: const Size(1600, 1200),
        listMaxWidth: double.infinity,
      );

      expect(tester.getSize(find.byKey(const ValueKey('list'))).width, 1600);
    });

    testWidgets('caps that module anyway once it is reviewing', (tester) async {
      await pump(
        tester,
        surface: const Size(1600, 1200),
        listMaxWidth: double.infinity,
      );
      await showProgress(tester);

      expect(
        tester.getSize(find.byKey(const ValueKey('progress'))).width,
        CenteredContent.readingMeasure,
      );
    });
  });
}
