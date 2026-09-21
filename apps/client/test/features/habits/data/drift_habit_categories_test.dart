import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/habits/data/drift_habit_repository.dart';
import 'package:nisabitus/features/habits/domain/habit_draft.dart';
import 'package:nisabitus/features/habits/domain/habit_frequency.dart';
import 'package:nisabitus/features/habits/domain/habit_repository.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repository;
  final monday = DateTime(2026, 3, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftHabitRepository(db);
  });
  tearDown(() => db.close());

  Future<String> habit(String name, {String? category}) async =>
      (await repository.create(
        HabitDraft(
          name: name,
          frequency: HabitFrequency.daily,
          category: category,
        ),
        on: monday,
      )).id;

  group('the categories the user has used', () {
    test('are empty until something is filed under one', () async {
      await habit('Meditar');

      expect(await repository.categories(), isEmpty);
    });

    test('are listed once each, however many habits use them', () async {
      await habit('Ordenar el escritorio', category: 'Orden');
      await habit('Ordenar la cocina', category: 'Orden');
      await habit('Comprar verdura', category: 'Compras');

      expect(await repository.categories(), ['Compras', 'Orden']);
    });

    test('ignore a category that is only whitespace', () async {
      // The form writes null for a blank field, but a row could carry spaces
      // and a blank chip is a filter nobody can read.
      await habit('Meditar', category: '   ');

      expect(await repository.categories(), isEmpty);
    });

    test('sort without letting case decide the order', () async {
      await habit('Uno', category: 'zapallo');
      await habit('Dos', category: 'Ávido');

      expect(await repository.categories(), ['Ávido', 'zapallo']);
    });

    test('say what is there, both spellings included', () async {
      // Two spellings that differ by case are two categories in the rows.
      // Showing one and hiding the other would be the app deciding which of
      // the user's words was the real one.
      await habit('Uno', category: 'Orden');
      await habit('Dos', category: 'orden');

      expect(await repository.categories(), hasLength(2));
    });

    test('lose a category when the last habit leaves it', () async {
      // The cost of deriving them: a category exists because something is
      // filed under it.
      final id = await habit('Ordenar', category: 'Orden');

      await repository.delete(id);

      expect(await repository.categories(), isEmpty);
    });
  });

  group('narrowing the figures to one category', () {
    final week = DateRange(monday, monday.add(const Duration(days: 6)));

    test('counts only that category completions', () async {
      final orden = await habit('Ordenar', category: 'Orden');
      final compras = await habit('Comprar', category: 'Compras');
      await repository.toggleCompletion(orden, monday);
      await repository.toggleCompletion(compras, monday);

      expect(await repository.totalCompletions(week), 2);
      expect(await repository.totalCompletions(week, category: 'Orden'), 1);
    });

    test('counts only that category habits', () async {
      await habit('Ordenar', category: 'Orden');
      await habit('Comprar', category: 'Compras');
      await habit('Meditar');

      expect(await repository.countHabits(), 3);
      expect(await repository.countHabits(category: 'Orden'), 1);
    });

    test('leaves the chart with only that category days', () async {
      final orden = await habit('Ordenar', category: 'Orden');
      final compras = await habit('Comprar', category: 'Compras');
      await repository.toggleCompletion(orden, monday);
      await repository.toggleCompletion(
        compras,
        monday.add(const Duration(days: 1)),
      );

      final perDay = await repository.completionsPerDay(
        week,
        category: 'Orden',
      );

      expect(perDay, hasLength(1));
      expect(perDay.single.day, monday);
    });

    test('no category asked for is every habit, not the blank one', () async {
      // Null means "all of them". A habit with no category is not what an
      // unfiltered view is about.
      await habit('Ordenar', category: 'Orden');
      await habit('Meditar');

      expect(await repository.countHabits(), 2);
    });
  });
}
