import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/time/selected_day_provider.dart';
import 'package:nisabitus/core/time/weekday.dart';
import 'package:nisabitus/features/exercise/domain/exercise_repository.dart';
import 'package:nisabitus/features/exercise/domain/scheduled_exercise.dart';
import 'package:nisabitus/features/exercise/presentation/exercise_providers.dart';
import 'package:nisabitus/features/exercise/presentation/exercise_view.dart';
import 'package:nisabitus/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  // A Wednesday.
  final day = DateTime(2026, 3, 11);
  final friday = DateTime(2026, 3, 13);

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

  ExerciseRepository repository() => container.read(exerciseRepositoryProvider);

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
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
          home: Scaffold(body: ExerciseView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<int> seedExercise([String name = 'Sentadilla']) async =>
      (await repository().createExercise(ExerciseDraft(name: name))).id;

  Future<ScheduledExercise> seedScheduled({
    ExerciseRecurrence? recurrence,
  }) async {
    final exerciseId = await seedExercise();

    return repository().schedule(
      day,
      ScheduledExerciseDraft(
        exerciseId: exerciseId,
        sets: 4,
        reps: 6,
        weightKg: 90,
      ),
      recurrence: recurrence,
    );
  }

  testWidgets('says nothing is written down rather than showing a blank list', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('Nada anotado para ese día'), findsOneWidget);
  });

  testWidgets('reads the target as sets by reps, in that order', (
    tester,
  ) async {
    // "4x6" is four sets of six. "6x4" is a different session entirely, and
    // gen-l10n renders placeholders alphabetically unless the ARB says
    // otherwise — which is exactly how that shipped once.
    await seedScheduled();
    await pumpView(tester);

    expect(find.textContaining('4x6 · 90 kg'), findsOneWidget);
  });

  testWidgets('ticks one off and records how it went', (tester) async {
    await seedScheduled();
    await pumpView(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cómo te fue'),
      'Salió redondo',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    final stored = (await repository().scheduledFor(day)).single;
    expect(stored.completed, isTrue);
    expect(stored.feedback, 'Salió redondo');
  });

  testWidgets('leaves the plan standing when nothing is said instead', (
    tester,
  ) async {
    // It went as written is the common case, and it should cost one tap plus
    // Guardar — not a form that blanks the weight because it was untouched.
    await seedScheduled();
    await pumpView(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect((await repository().scheduledFor(day)).single.weightKg, 90);
  });

  testWidgets('puts one back to pending without losing the feedback', (
    tester,
  ) async {
    final scheduled = await seedScheduled();
    await repository().complete(
      scheduled.id,
      const ExerciseCompletion(feedback: 'Pesó'),
    );
    await pumpView(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final stored = (await repository().scheduledFor(day)).single;
    expect(stored.completed, isFalse);
    expect(stored.feedback, 'Pesó');
  });

  testWidgets('corrects a movement from the form that schedules it', (
    tester,
  ) async {
    // The catalogue section is gone, and with it the only place a movement's
    // name could be fixed. The form that picks one is where that lives now:
    // losing the ability to correct a typo would be a real loss, dressed up
    // as a simplification.
    await seedExercise('Sentadila');
    await pumpView(tester);

    await tester.tap(find.byTooltip('Anotar ejercicio'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byTooltip('Editar ejercicio'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Sentadilla',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar').last);
    await tester.pumpAndSettle();

    expect((await repository().exercises()).single.name, 'Sentadilla');
    // And the form is still open on it, reading right: without the picker
    // being told, the typo would stay on screen until the dialog is closed
    // and reopened, which is where the correction was needed in the first
    // place.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Sentadilla'),
      ),
      findsOneWidget,
    );
    expect(find.text('Sentadila'), findsNothing);
  });

  testWidgets('removes a movement from the form that schedules it', (
    tester,
  ) async {
    // Deleting a movement is only reachable from here now. A repository that
    // can delete is not a feature: the user has to be able to get to it.
    await seedExercise();
    await pumpView(tester);

    await tester.tap(find.byTooltip('Anotar ejercicio'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byTooltip('Editar ejercicio'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Borrar'));
    await tester.pumpAndSettle();

    // Deleting the movement takes every day it was ever scheduled on with
    // it. The confirmation has to say so before it happens, not after.
    expect(
      find.textContaining('todos los días en que lo anotaste'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Borrar').last);
    await tester.pumpAndSettle();

    expect(await repository().exercises(), isEmpty);
    // The picker cannot keep offering something that is gone.
    expect(find.text('Sentadilla'), findsNothing);
  });

  testWidgets('offers to stop a repetition only on something that repeats', (
    tester,
  ) async {
    await seedScheduled();
    await pumpView(tester);

    expect(find.byTooltip('Dejar de repetir'), findsNothing);
  });

  testWidgets('stops a repetition from the day forward', (tester) async {
    await seedScheduled(
      recurrence: ExerciseRecurrence(
        days: const {Weekday.wednesday, Weekday.friday},
        type: RecurrenceType.weeks,
        weeks: 2,
      ),
    );
    await pumpView(tester);
    expect(await repository().scheduledFor(friday), hasLength(1));

    await tester.tap(find.byTooltip('Dejar de repetir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Dejar de repetir'));
    await tester.pumpAndSettle();

    // The day it was stopped from stays; the later ones are gone.
    expect(await repository().scheduledFor(day), hasLength(1));
    expect(await repository().scheduledFor(friday), isEmpty);
  });
}
