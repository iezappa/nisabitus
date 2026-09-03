import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/discipline/domain/discipline_repository.dart';
import 'package:nisabitus/features/discipline/presentation/discipline_providers.dart';
import 'package:nisabitus/features/discipline/presentation/discipline_section.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final day = DateTime(2026, 3, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(day),
        selectedDayProvider.overrideWith((ref) => day),
      ],
    );
    addTearDown(container.dispose);
  });
  tearDown(() => db.close());

  DisciplineRepository repository() =>
      container.read(disciplineRepositoryProvider);

  Future<void> pumpSection(WidgetTester tester) async {
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
          home: Scaffold(
            body: SingleChildScrollView(child: DisciplineSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('writes one down without any catalogue behind it', (
    tester,
  ) async {
    // Typed, not picked: "Natación" does not need a definition somewhere
    // else before it can be logged.
    await pumpSection(tester);

    await tester.tap(find.byTooltip('Anotar disciplina'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Qué practicaste'),
      'Natación',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Distancia'),
      '2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    final stored = (await repository().forDay(day)).single;
    expect(stored.name, 'Natación');
    expect(stored.durationMinutes, 30);
    expect(stored.distanceKm, 2);
  });

  testWidgets('reads a session in time and distance, not in sets', (
    tester,
  ) async {
    await repository().schedule(
      day,
      const DisciplineDraft(
        name: 'Natación',
        durationMinutes: 45,
        distanceKm: 2.5,
      ),
    );
    await pumpSection(tester);

    expect(find.textContaining('45 min · 2.5 km'), findsOneWidget);
  });

  testWidgets('writes a whole number of kilometres without a decimal point', (
    tester,
  ) async {
    await repository().schedule(
      day,
      const DisciplineDraft(name: 'Correr', durationMinutes: 30, distanceKm: 5),
    );
    await pumpSection(tester);

    expect(find.textContaining('5 km'), findsOneWidget);
    expect(find.textContaining('5.0 km'), findsNothing);
  });

  testWidgets('ticks one off and records how it went', (tester) async {
    await repository().schedule(
      day,
      const DisciplineDraft(name: 'Natación', durationMinutes: 45),
    );
    await pumpSection(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cómo te fue'),
      'Fría el agua',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    final stored = (await repository().forDay(day)).single;
    expect(stored.completed, isTrue);
    expect(stored.feedback, 'Fría el agua');
  });

  testWidgets('says nothing was practised rather than showing a blank list', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('Nada practicado ese día'), findsOneWidget);
  });
}
