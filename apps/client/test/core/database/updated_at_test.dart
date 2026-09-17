// Every repository write moves `updatedAt` (STACK-APPS-DINAMICAS.md 1.1).
//
// Each case creates a record, pins its `updatedAt` far in the past, runs one
// write through the repository and checks the stamp moved. A write that
// forgets it would leave a record a later sync considers stale.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/discipline/data/drift_discipline_repository.dart';
import 'package:nisabitus/features/discipline/domain/discipline_repository.dart';
import 'package:nisabitus/features/exercise/data/drift_exercise_repository.dart';
import 'package:nisabitus/features/exercise/domain/exercise_repository.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/features/hydration/data/drift_hydration_repository.dart';
import 'package:nisabitus/features/hydration/domain/hydration.dart';
import 'package:nisabitus/features/journal/data/drift_journal_repository.dart';
import 'package:nisabitus/features/journal/domain/journal_content.dart';
import 'package:nisabitus/features/medication/data/drift_medication_repository.dart';
import 'package:nisabitus/features/medication/domain/medication_repository.dart';
import 'package:nisabitus/features/meditation/data/drift_meditation_repository.dart';
import 'package:nisabitus/features/meditation/domain/meditation_repository.dart';
import 'package:nisabitus/features/nutrition/data/drift_nutrition_repository.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition.dart';
import 'package:nisabitus/features/nutrition/domain/nutrition_repository.dart';
import 'package:nisabitus/features/pomodoro/data/drift_pomodoro_repository.dart';
import 'package:nisabitus/features/pomodoro/domain/pomodoro_draft.dart';
import 'package:nisabitus/features/sleep/data/drift_sleep_repository.dart';
import 'package:nisabitus/features/streaks/data/drift_streak_repository.dart';
import 'package:nisabitus/features/todo/data/drift_todo_repository.dart';
import 'package:nisabitus/features/todo/domain/task.dart';
import 'package:nisabitus/features/todo/domain/todo_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final day = DateTime(2026, 3, 11);
  final longAgo = DateTime(2001);

  Future<void> age(String table) => db.customStatement(
    'UPDATE "$table" SET updated_at = ?',
    [longAgo.millisecondsSinceEpoch ~/ 1000],
  );

  Future<DateTime> stampOf(String table) async {
    final row = await db
        .customSelect('SELECT MIN(updated_at) AS at FROM "$table"')
        .getSingle();
    return DateTime.fromMillisecondsSinceEpoch(row.read<int>('at') * 1000);
  }

  Future<void> expectTouched(
    String table,
    Future<void> Function() write,
  ) async {
    await age(table);
    await write();
    expect(
      (await stampOf(table)).isAfter(longAgo),
      isTrue,
      reason: '$table kept its old updatedAt',
    );
  }

  test('habits: update and status change', () async {
    final repo = DriftHabitRepository(db);
    const draft = HabitDraft(name: 'Leer', frequency: HabitFrequency.daily);
    final habit = await repo.create(draft, on: day);

    await expectTouched('habits', () => repo.update(habit.id, draft, on: day));
    await expectTouched(
      'habits',
      () => repo.changeStatus(habit.id, HabitStatus.values.last, day),
    );
  });

  test('todo: project, task and status', () async {
    final repo = DriftTodoRepository(db);
    final project = await repo.createProject('Casa');
    final task = await repo.createTask(
      TaskDraft(title: 'Pintar', projectId: project.id),
    );

    await expectTouched(
      'projects',
      () => repo.updateProject(project.id, name: 'Hogar'),
    );
    await expectTouched(
      'todo_tasks',
      () => repo.updateTask(
        task.id,
        TaskDraft(title: 'Pintar todo', projectId: project.id),
      ),
    );
    await expectTouched(
      'todo_tasks',
      () => repo.setTaskStatus(task.id, TaskStatus.done),
    );
  });

  test('exercise: movement, scheduled day, complete and reopen', () async {
    final repo = DriftExerciseRepository(db);
    final exercise = await repo.createExercise(
      const ExerciseDraft(name: 'Remo'),
    );
    final scheduled = await repo.schedule(
      day,
      ScheduledExerciseDraft(exerciseId: exercise.id, sets: 3, reps: 10),
    );

    await expectTouched(
      'exercises',
      () => repo.updateExercise(exercise.id, const ExerciseDraft(name: 'R')),
    );
    await expectTouched(
      'scheduled_exercises',
      () => repo.complete(scheduled.id, const ExerciseCompletion()),
    );
    await expectTouched('scheduled_exercises', () => repo.reopen(scheduled.id));
  });

  test('discipline: update and complete', () async {
    final repo = DriftDisciplineRepository(db);
    const draft = DisciplineDraft(name: 'Natación', durationMinutes: 30);
    final session = await repo.schedule(day, draft);

    await expectTouched('disciplines', () => repo.update(session.id, draft));
    await expectTouched(
      'disciplines',
      () => repo.complete(session.id, const DisciplineCompletion()),
    );
  });

  test('medication, meditation, pomodoro and streaks: updates', () async {
    final medications = DriftMedicationRepository(db);
    const medication = MedicationDraft(name: 'Vitamina D');
    final created = await medications.create(medication, today: day);
    await expectTouched(
      'medications',
      () => medications.update(created.id, medication, today: day),
    );

    final meditation = DriftMeditationRepository(db);
    final sat = await meditation.add(day, const MeditationDraft(minutes: 10));
    await expectTouched(
      'meditation_sessions',
      () => meditation.update(sat.id, const MeditationDraft(minutes: 20)),
    );

    final pomodoro = DriftPomodoroRepository(db);
    final session = await pomodoro.create(const PomodoroDraft(name: 'Foco'));
    await expectTouched(
      'pomodoro_sessions',
      () => pomodoro.completeCycle(session.id),
    );

    final streaks = DriftStreakRepository(db);
    final streak = await streaks.create('Sin azúcar', on: day);
    await expectTouched('streaks', () => streaks.rename(streak.id, 'Nada'));
    await expectTouched('streaks', () => streaks.increment(streak.id, on: day));
  });

  test('nutrition: entry, food and goal', () async {
    final repo = DriftNutritionRepository(db);
    final entry = await repo.addEntry(day, const FoodDraft(name: 'Avena'));
    await expectTouched(
      'food_entries',
      () => repo.updateEntry(entry.id, const FoodDraft(name: 'Avena cocida')),
    );

    await db.delete(db.foods).go();
    final food = await repo.saveFood(
      Food(id: '', name: 'Pan', per100g: Macros.empty),
    );
    await expectTouched(
      'foods',
      () => repo.saveFood(
        Food(id: food.id, name: 'Pan casero', per100g: Macros.empty),
      ),
    );

    final goal = NutritionGoal(calories: 1, protein: 1, carbs: 1, fat: 1);
    await repo.saveGoal(goal);
    await expectTouched('nutrition_goals', () => repo.saveGoal(goal));
  });

  test('upserts: hydration goal, journal day and sleep night', () async {
    final hydration = DriftHydrationRepository(db);
    await hydration.saveGoal(HydrationGoal(millilitres: 2000));
    await expectTouched(
      'hydration_goals',
      () => hydration.saveGoal(HydrationGoal(millilitres: 2500)),
    );

    final journal = DriftJournalRepository(db);
    await journal.save(day, const JournalContent(mood: 'bien'));
    await expectTouched(
      'mood_entries',
      () => journal.save(day, const JournalContent(mood: 'mejor')),
    );

    final sleep = DriftSleepRepository(db);
    await sleep.save(day, 7);
    await expectTouched('sleep_logs', () => sleep.save(day, 8));
  });
}
