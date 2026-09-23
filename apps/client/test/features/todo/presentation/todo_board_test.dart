import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/theme/app_theme.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/project.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';
import 'package:nisabitus/features/todo/presentation/todo_providers.dart';
import 'package:nisabitus/features/todo/presentation/todo_screen.dart';
import 'package:nisabitus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;
  late ProviderContainer container;
  late Project root;
  late Project child;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTodoRepository(db);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    root = await repository.createProject('Casa');
    child = await repository.createProject('Cocina', parentId: root.id);
    container.read(selectedProjectIdProvider.notifier).state = root.id;
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> pumpBoard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
          home: TodoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('include subprojects', () {
    testWidgets('puts the tasks of a subproject on the board', (tester) async {
      // The bug: a task pulled in from a subproject sits in a column of its
      // own project's board, so grouped by the id it carries it belonged to
      // no column on screen and was drawn nowhere at all.
      await repository.createTask(
        TaskDraft(title: 'Ordenar la alacena', projectId: child.id),
      );
      await pumpBoard(tester);

      expect(find.text('Ordenar la alacena'), findsOne);
      expect(find.text('Cocina'), findsWidgets, reason: 'says where it lives');
    });

    testWidgets('takes them off again when it is switched off', (tester) async {
      await repository.createTask(
        TaskDraft(title: 'Ordenar la alacena', projectId: child.id),
      );
      await pumpBoard(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Ordenar la alacena'), findsNothing);
    });
  });

  group('the filter bar', () {
    testWidgets('opens at the board edge and ends at the far one', (
      tester,
    ) async {
      // Two questions, two sides: what the board is about on the left,
      // what to look at right now on the right. The bar used to float in
      // the middle of the window, and the filters stopped halfway across
      // it because a flexible label was taking half the free space.
      await repository.createTask(
        TaskDraft(title: 'Tarea', projectId: root.id),
      );
      await pumpBoard(tester);

      final edge = tester.getTopRight(find.byType(VerticalDivider)).dx;
      final scope = tester.getTopLeft(find.byType(Switch));
      final filter = tester.getRect(
        find.ancestor(
          of: find.text('Propietario'),
          matching: find.byType(TextField),
        ),
      );
      final bar = tester.getRect(
        find
            .ancestor(of: find.byType(Switch), matching: find.byType(Row))
            .first,
      );

      expect(
        scope.dx - edge,
        lessThan(Gap.lg),
        reason: 'the scope opens the board',
      );
      expect(
        bar.right - filter.right,
        lessThan(1.0),
        reason: 'the filters end where the bar does',
      );
      expect(filter.left, greaterThan(scope.dx + 200));
    });

    testWidgets('narrows the board to one owner', (tester) async {
      await repository.createTask(
        TaskDraft(title: 'Firmar', projectId: root.id, owner: 'Ana'),
      );
      await repository.createTask(TaskDraft(title: 'Mía', projectId: root.id));
      await pumpBoard(tester);

      await tester.enterText(
        find.ancestor(
          of: find.text('Propietario'),
          matching: find.byType(TextField),
        ),
        'ana',
      );
      await tester.pumpAndSettle();

      expect(find.text('Firmar'), findsOne);
      expect(find.text('Mía'), findsNothing);
    });
  });

  testWidgets('a card says whose the task is', (tester) async {
    await repository.createTask(
      TaskDraft(title: 'Firmar', projectId: root.id, owner: 'Ana'),
    );
    await repository.createTask(TaskDraft(title: 'Mía', projectId: root.id));
    await pumpBoard(tester);

    // Once, on the card that has an owner: a board where every card says
    // "mine" says nothing.
    expect(find.text('Ana'), findsOne);
  });
}
