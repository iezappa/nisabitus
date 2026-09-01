import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/habits/domain/habit.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/features/habits/presentation/widgets/habit_form_dialog.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  /// The draft the form last returned, filled once it is submitted.
  HabitDraft? draft;

  setUp(() => draft = null);

  Future<void> openForm(WidgetTester tester, {Habit? existing}) async {
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  draft = await showHabitForm(context, existing: existing),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String value) =>
      tester.enterText(find.widgetWithText(TextFormField, label), value);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  group('the description field', () {
    testWidgets('is offered when creating a habit', (tester) async {
      await openForm(tester);

      expect(find.widgetWithText(TextFormField, 'Descripción'), findsOneWidget);
    });

    testWidgets('comes back filled when editing one', (tester) async {
      await openForm(
        tester,
        existing: Habit(
          id: 1,
          name: 'Meditar',
          frequency: HabitFrequency.daily,
          status: HabitStatus.pending,
          createdAt: DateTime(2026, 3, 9),
          scheduledDate: DateTime(2026, 3, 9),
          description: 'Diez minutos',
        ),
      );

      expect(find.text('Diez minutos'), findsOneWidget);
    });

    testWidgets('reaches the draft once the form is saved', (tester) async {
      await openForm(tester);
      await type(tester, 'Nombre', 'Meditar');
      await type(tester, 'Descripción', 'Diez minutos antes de dormir');
      await save(tester);

      expect(draft?.description, 'Diez minutos antes de dormir');
    });

    testWidgets('stays null when it is left blank', (tester) async {
      await openForm(tester);
      await type(tester, 'Nombre', 'Meditar');
      await save(tester);

      expect(draft?.description, isNull);
    });
  });
}
