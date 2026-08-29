import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/database/app_database.dart';
import 'package:nisabit/core/database/database_provider.dart';
import 'package:nisabit/features/streaks/presentation/streak_providers.dart';
import 'package:nisabit/features/streaks/presentation/streaks_section.dart';
import 'package:nisabit/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> pump(WidgetTester tester, {Size size = const Size(700, 500)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(body: StreaksSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed(int count) async {
    final actions = container.read(streakActionsProvider);
    for (var i = 1; i <= count; i++) {
      await actions.create('Racha $i');
    }
  }

  group('the reset button', () {
    testWidgets('sits on the card, not behind a long press', (tester) async {
      await seed(1);
      await pump(tester);

      expect(find.text('Reiniciar'), findsOneWidget);
    });

    testWidgets('sends the count back to zero', (tester) async {
      await seed(1);
      await pump(tester);
      await tester.tap(find.byTooltip('+1'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Reiniciar'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('keeps the record the streak had reached', (tester) async {
      await seed(1);
      await pump(tester);
      await tester.tap(find.byTooltip('+1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('+1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reiniciar'));
      await tester.pumpAndSettle();

      expect(find.text('Récord: 2'), findsOneWidget);
    });
  });

  group('the band', () {
    testWidgets('scrolls with an ordinary mouse wheel', (tester) async {
      // Six cards at 200 wide overflow a 700 wide window several times over.
      await seed(6);
      await pump(tester);

      final list = find.byType(Scrollable).first;
      final before = tester.widget<Scrollable>(list).controller!.offset;

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      final band = tester.getCenter(find.text('RACHA 1'));
      await tester.sendEventToBinding(pointer.hover(band));
      // A wheel only ever reports a vertical delta; a horizontal list reads
      // the horizontal one, so without the fix this moves nothing.
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 220)));
      await tester.pumpAndSettle();

      final after = tester.widget<Scrollable>(list).controller!.offset;
      expect(after, greaterThan(before));
    });

    testWidgets('reaches a card that started off screen', (tester) async {
      await seed(6);
      await pump(tester);
      expect(find.text('RACHA 6'), findsNothing);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('RACHA 1'))),
      );
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 2000)));
      await tester.pumpAndSettle();

      expect(find.text('RACHA 6'), findsOneWidget);
    });

    testWidgets('stops at the end instead of running past it', (tester) async {
      await seed(6);
      await pump(tester);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('RACHA 1'))),
      );
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 99999)));
      await tester.pumpAndSettle();

      final scrollable = tester.widget<Scrollable>(find.byType(Scrollable).first);
      final position = scrollable.controller!.position;
      expect(position.pixels, position.maxScrollExtent);
    });

    testWidgets('shows a scrollbar so the overflow is visible', (tester) async {
      await seed(6);
      await pump(tester);

      expect(find.byType(Scrollbar), findsOneWidget);
    });
  });

  group('the streak editor', () {
    testWidgets('opens by tapping the card', (tester) async {
      await seed(1);
      await pump(tester);

      await tester.tap(find.text('RACHA 1'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Racha 1'), findsOneWidget);
    });

    testWidgets('renames the streak', (tester) async {
      await seed(1);
      await pump(tester);
      await tester.tap(find.text('RACHA 1'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Meditar');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('MEDITAR'), findsOneWidget);
    });

    testWidgets('offers a bin, as every editing modal does', (tester) async {
      await seed(1);
      await pump(tester);

      await tester.tap(find.text('RACHA 1'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('deletes only after the confirmation', (tester) async {
      await seed(1);
      await pump(tester);
      await tester.tap(find.text('RACHA 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar Racha 1?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('RACHA 1'), findsNothing);
      expect(find.text('Todavía no hay rachas'), findsOneWidget);
    });

    testWidgets('keeps the streak when the confirmation is refused', (
      tester,
    ) async {
      await seed(1);
      await pump(tester);
      await tester.tap(find.text('RACHA 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // The editor sits behind the confirmation and has its own Cancelar.
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('¿Borrar Racha 1?'),
            matching: find.byType(AlertDialog),
          ),
          matching: find.widgetWithText(TextButton, 'Cancelar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Racha 1'), findsWidgets);
    });
  });
}
