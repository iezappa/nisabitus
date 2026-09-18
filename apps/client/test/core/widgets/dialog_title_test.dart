import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/widgets/dialog_title.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

/// Every editing modal deletes through this bin, so it is where a failed
/// delete has to be told rather than swallowed.
void main() {
  testWidgets('says so when the delete fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: DialogTitle(
                    text: 'Edit',
                    deleteLabel: 'Read',
                    onDelete: () async => throw StateError('refused'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't delete. Please try again."), findsOneWidget);
  });
}
