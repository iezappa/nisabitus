import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/meditation/domain/meditation_repository.dart';
import 'package:nisabitus/features/meditation/presentation/meditation_providers.dart';
import 'package:nisabitus/features/meditation/presentation/meditation_screen.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final day = DateTime(2026, 3, 11);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        todayProvider.overrideWithValue(day),
        selectedDayProvider.overrideWith((ref) => day),
      ],
    );
    addTearDown(container.dispose);
  });
  tearDown(() => db.close());

  MeditationRepository repository() =>
      container.read(meditationRepositoryProvider);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          home: MeditationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('writes a sitting down through the form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect((await repository().sessionsFor(day)).single.minutes, 20);
  });

  testWidgets('adds the sittings of a day up in the heading', (tester) async {
    await repository().add(day, const MeditationDraft(minutes: 10));
    await repository().add(day, const MeditationDraft(minutes: 15));
    await pumpScreen(tester);

    expect(find.text('25 min ese día'), findsOneWidget);
  });

  testWidgets('shows the note next to the sitting it belongs to', (
    tester,
  ) async {
    await repository().add(
      day,
      const MeditationDraft(minutes: 20, note: 'Costó arrancar'),
    );
    await pumpScreen(tester);

    expect(find.text('Costó arrancar'), findsOneWidget);
  });

  testWidgets('refuses a sitting of no time at the form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ingresá un número'), findsOneWidget);
    expect(await repository().sessionsFor(day), isEmpty);
  });

  testWidgets('says nothing was sat rather than showing an empty list', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Ese día no anotaste nada'), findsOneWidget);
  });
}
