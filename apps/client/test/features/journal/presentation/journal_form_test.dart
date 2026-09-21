import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/journal/domain/journal_content.dart';
import 'package:nisabitus/features/journal/presentation/widgets/journal_form.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, {JournalContent? initial}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // Pinned: these assertions read the Spanish copy.
        locale: const Locale('es'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: JournalForm(
              initial: initial ?? const JournalContent(),
              hasEntry: false,
              onSave: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The decoration of the field carrying [label].
  InputDecoration decorationOf(WidgetTester tester, String label) {
    final field = tester.widget<TextField>(
      find.ancestor(of: find.text(label), matching: find.byType(TextField)),
    );
    return field.decoration!;
  }

  // A hint is painted exactly where the user types. These fields asked for a
  // hint and a label at once, and on a box six lines tall the un-floated
  // label sits down the middle of it while the hint waits at the top — two
  // pieces of grey text in a box that has neither.
  const prompts = {
    'Estado emocional': '¿Cómo te sentiste?',
    'Gratitud': '¿Qué agradecés de hoy?',
    'Foco del día': '¿En qué pusiste tu atención?',
    'Reflexión': 'Escribí lo que quieras. Sin apuro.',
    'Intención para mañana': '¿Con qué querés empezar mañana?',
  };

  testWidgets('no prompt is painted where the user writes', (tester) async {
    await pump(tester);

    for (final label in prompts.keys) {
      expect(
        decorationOf(tester, label).hintText,
        isNull,
        reason: '$label still carries a hint',
      );
    }
  });

  testWidgets('every field keeps its question under the box', (tester) async {
    await pump(tester);

    for (final MapEntry(key: label, value: prompt) in prompts.entries) {
      expect(decorationOf(tester, label).helperText, prompt);
    }
  });

  testWidgets('a tall field puts its label on the first line', (tester) async {
    // Without this the label is centred down a six-line box, which is what
    // made these read as broken.
    await pump(tester);

    expect(decorationOf(tester, 'Reflexión').alignLabelWithHint, isTrue);
    // The one-line field has nothing to align against.
    expect(
      decorationOf(tester, 'Estado emocional').alignLabelWithHint,
      isFalse,
    );
  });

  testWidgets('the question stays readable while it is answered', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(
      find.ancestor(
        of: find.text('Gratitud'),
        matching: find.byType(TextField),
      ),
      'El café de la mañana',
    );
    await tester.pumpAndSettle();

    expect(find.text('¿Qué agradecés de hoy?'), findsOne);
    expect(find.text('El café de la mañana'), findsOne);
  });
}
