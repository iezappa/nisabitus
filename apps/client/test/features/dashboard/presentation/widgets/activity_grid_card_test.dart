import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nisabitus/features/dashboard/presentation/widgets/activity_grid_card.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  // A Wednesday, so the last column is a part week.
  final today = DateTime(2026, 9, 16);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(today),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> drank(DateTime day, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      await db
          .into(db.waterEntries)
          .insert(WaterEntriesCompanion.insert(date: day, millilitres: 250));
    }
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    Size surface = const Size(900, 700),
  }) async {
    await tester.binding.setSurfaceSize(surface);
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
          home: Scaffold(body: ActivityGridCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Every square of the grid, legend swatches excluded: those are a fixed
  /// ten across and would be counted as five more days.
  Iterable<Container> squaresOf(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .where((box) => (box.constraints?.maxWidth ?? 0) != 10);

  testWidgets('draws a square for every day of the window', (tester) async {
    await pumpCard(tester);

    // Exactly the advertised number of weeks, whatever weekday today is.
    expect(squaresOf(tester), hasLength(activityWeeks * 7));
  });

  testWidgets('leaves the days that have not arrived alone', (tester) async {
    // Today is a Wednesday, so four squares of the last column are days in
    // the future: drawn away, and with nothing to say under the cursor.
    await pumpCard(tester);

    expect(find.byType(Tooltip), findsNWidgets(activityWeeks * 7 - 4));
  });

  testWidgets('says so when nothing has been written down', (tester) async {
    await pumpCard(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));

    expect(find.text(l10n.dashboardActivityEmpty), findsOne);
  });

  testWidgets('counts what was recorded once it exists', (tester) async {
    await drank(today, times: 3);
    await drank(today.subtract(const Duration(days: 1)));
    await pumpCard(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(l10n.dashboardActivityEmpty), findsNothing);
    expect(
      find.textContaining(l10n.dashboardActivityTotal(4)),
      findsOne,
      reason: 'four entries over two days',
    );
    expect(find.textContaining(l10n.dashboardActivityRun(2)), findsOne);
  });

  testWidgets('shades a busy day darker than a quiet one', (tester) async {
    await drank(today, times: 12);
    await drank(today.subtract(const Duration(days: 1)));
    await pumpCard(tester);

    final colors = Theme.of(tester.element(find.byType(ActivityGridCard)))
        .colorScheme;
    final shades = squaresOf(tester)
        .map((box) => (box.decoration as BoxDecoration?)?.color)
        .toSet();

    expect(shades, contains(activityShade(colors, 4)));
    expect(shades, contains(activityShade(colors, 1)));
    expect(shades, contains(activityShade(colors, 0)));
  });

  testWidgets('keeps the whole window on a phone-width screen', (tester) async {
    await pumpCard(tester, surface: const Size(360, 700));

    expect(squaresOf(tester), hasLength(activityWeeks * 7));
    expect(tester.takeException(), isNull);
  });
}
