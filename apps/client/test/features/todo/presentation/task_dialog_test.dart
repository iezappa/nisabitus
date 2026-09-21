import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';
import 'package:nisabitus/features/todo/presentation/todo_providers.dart';
import 'package:nisabitus/features/todo/presentation/widgets/task_dialog.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;
  late ProviderContainer container;
  late String projectId;
  late String taskId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTodoRepository(db);
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    final project = await repository.createProject('Nisabitus');
    projectId = project.id;
    taskId = (await repository.createTask(
      TaskDraft(title: 'Escribir el test', projectId: projectId),
    )).id;
    // The board and the task list both read it.
    container.read(selectedProjectIdProvider.notifier).state = projectId;
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> openTask(WidgetTester tester) async {
    late BuildContext host;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
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
            body: Builder(
              builder: (context) {
                host = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final task = (await repository.tasks(projectId)).single;
    // Not awaited: it only completes when the dialog is dismissed.
    unawaited(showTaskDialog(host, projectId: projectId, existing: task));
    await tester.pumpAndSettle();
  }

  /// The decoration of the field carrying [label].
  InputDecoration decorationOf(WidgetTester tester, String label) {
    final field = tester.widget<TextField>(
      find.ancestor(of: find.text(label), matching: find.byType(TextField)),
    );
    return field.decoration!;
  }

  testWidgets('an existing task opens as something to read', (tester) async {
    await openTask(tester);

    expect(find.text('Escribir el test'), findsWidgets);
    // The read view, not the form: no Save until Edit is pressed.
    expect(find.text('Guardar'), findsNothing);
    expect(find.text('Cerrar'), findsOne);
  });

  group('the composers', () {
    // A hint is painted where the user types. Anything that stops it being
    // cleared in time leaves the placeholder sitting on top of the text, and
    // that is exactly what was reported. A label moves out to the border as
    // soon as there is text, so there is nothing left underneath.
    testWidgets('label rather than hint, so nothing sits under the text', (
      tester,
    ) async {
      await openTask(tester);

      for (final label in ['Agregar un ítem', 'Agregar una novedad']) {
        final decoration = decorationOf(tester, label);
        expect(decoration.hintText, isNull, reason: '$label uses a hint');
        expect(decoration.labelText, label);
      }
    });

    testWidgets('a checklist line is written and the field cleared', (
      tester,
    ) async {
      await openTask(tester);

      await tester.enterText(
        find.ancestor(
          of: find.text('Agregar un ítem'),
          matching: find.byType(TextField),
        ),
        'Probar el modal',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        (await repository.checklist(taskId)).single.content,
        'Probar el modal',
      );
      final field = tester.widget<TextField>(
        find.ancestor(
          of: find.text('Agregar un ítem'),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('an update is written and the field cleared', (tester) async {
      await openTask(tester);

      await tester.enterText(
        find.ancestor(
          of: find.text('Agregar una novedad'),
          matching: find.byType(TextField),
        ),
        'Empezado',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect((await repository.comments(taskId)).single.content, 'Empezado');
      final field = tester.widget<TextField>(
        find.ancestor(
          of: find.text('Agregar una novedad'),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, isEmpty);
    });
  });
}
