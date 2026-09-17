import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/uuid.dart';
import 'package:nisabitus/features/backup/data/drift_backup_repository.dart';
import 'package:nisabitus/features/backup/data/legacy_backup_ids.dart';
import 'package:nisabitus/features/backup/domain/backup_document.dart';

/// A format 1 file: integer ids, no `updatedAt`, written by schema v13.
String _formatOneFile() => jsonEncode({
  'app': 'nisabitus',
  'format': 1,
  'schemaVersion': 13,
  'exportedAt': DateTime(2026, 9, 1).millisecondsSinceEpoch,
  'tables': {
    'habits': [
      {
        'id': 5,
        'name': 'Leer',
        'frequency': 'DAILY',
        'targetCount': 1,
        'repeatForever': false,
        'repeatDays': '',
        'status': 'ACTIVE',
        'createdAt': DateTime(2026, 1, 2).millisecondsSinceEpoch,
        'scheduledDate': DateTime(2026, 1, 2).millisecondsSinceEpoch,
      },
      {
        'id': 7,
        'name': 'Meditar',
        'frequency': 'DAILY',
        'targetCount': 1,
        'repeatForever': false,
        'repeatDays': '',
        'status': 'ACTIVE',
        'createdAt': DateTime(2026, 1, 3).millisecondsSinceEpoch,
        'scheduledDate': DateTime(2026, 1, 3).millisecondsSinceEpoch,
      },
    ],
    'habit_completions': [
      {'id': 1, 'habitId': 7, 'completionDate': 0},
      {'id': 2, 'habitId': 5, 'completionDate': 0},
      {'id': 3, 'habitId': 7, 'completionDate': 86400000},
    ],
    'projects': [
      {'id': 2, 'name': 'Raíz', 'parentId': null},
      {'id': 1, 'name': 'Hijo', 'parentId': 2},
    ],
    'todo_tasks': [
      {
        'id': 1,
        'title': 'Tarea',
        'priority': 'LOW',
        'status': 'TODO',
        'projectId': 1,
      },
    ],
    'task_comments': [
      {'id': 4, 'taskId': 1, 'content': 'Hola', 'createdAt': 0},
    ],
    'streaks': [
      {'id': 1, 'name': 'Racha', 'count': 2, 'maxStreak': 2, 'lastUpdated': 0},
    ],
    'streak_history_entries': [
      {'id': 1, 'streakId': 1, 'count': 2, 'reachedAt': 0},
    ],
    'exercises': [
      {'id': 3, 'name': 'Remo'},
    ],
    'scheduled_exercises': [
      {
        'id': 1,
        'exerciseId': 3,
        'scheduledDate': 0,
        'sets': 3,
        'reps': 10,
        'completed': false,
        'repeatDays': '',
        'repeatForever': false,
      },
    ],
    'medications': [
      {'id': 9, 'name': 'Vitamina D', 'kind': 'SUPPLEMENT', 'active': true},
    ],
    'medication_intakes': [
      {'id': 1, 'medicationId': 9, 'date': 0},
    ],
    'nutrition_goals': [
      {'id': 1, 'calories': 1800, 'protein': 90, 'carbs': 200, 'fat': 60},
    ],
  },
});

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  BackupDocument parse(String text) =>
      BackupDocument.parse(text, supportedSchemaVersion: db.schemaVersion);

  group('upgradeLegacyIds', () {
    test('gives every row a UUID and keeps references consistent', () {
      final upgraded = upgradeLegacyIds(parse(_formatOneFile()));

      final habits = {
        for (final row in upgraded.tables['habits']!) row['name']: row['id'],
      };
      expect(habits.values.every((id) => isUuid(id as String)), isTrue);

      final completions = upgraded.tables['habit_completions']!;
      expect(completions.map((row) => row['habitId']), [
        habits['Meditar'],
        habits['Leer'],
        habits['Meditar'],
      ]);
    });

    test('maps the same old id to different UUIDs in different tables', () {
      final upgraded = upgradeLegacyIds(parse(_formatOneFile()));

      // Project 1 and task 1 share an integer id; they must not share a UUID.
      final hijo = upgraded.tables['projects']!.firstWhere(
        (row) => row['name'] == 'Hijo',
      );
      final task = upgraded.tables['todo_tasks']!.single;
      expect(task['id'], isNot(hijo['id']));
      expect(task['projectId'], hijo['id']);
    });

    test('stamps updatedAt from createdAt, lastUpdated or the export', () {
      final document = parse(_formatOneFile());
      final upgraded = upgradeLegacyIds(document);

      final leer = upgraded.tables['habits']!.firstWhere(
        (row) => row['name'] == 'Leer',
      );
      expect(leer['updatedAt'], DateTime(2026, 1, 2).millisecondsSinceEpoch);
      expect(
        upgraded.tables['exercises']!.single['updatedAt'],
        document.exportedAt.millisecondsSinceEpoch,
      );
    });

    test('puts single-row goals under the singleton id', () {
      final upgraded = upgradeLegacyIds(parse(_formatOneFile()));

      expect(
        upgraded.tables['nutrition_goals']!.single['id'],
        AppDatabase.singletonId,
      );
    });

    test('leaves a current-format document as it is', () {
      final current = BackupDocument(
        schemaVersion: 14,
        exportedAt: DateTime(2026),
        tables: const {},
      );
      expect(identical(upgradeLegacyIds(current), current), isTrue);
    });
  });

  group('restoring a format 1 file', () {
    test('keeps every relation intact in the store', () async {
      final repository = DriftBackupRepository(db);

      await repository.restore(parse(_formatOneFile()));

      final habits = {
        for (final h in await db.select(db.habits).get()) h.id: h.name,
      };
      final perHabit = <String, int>{};
      for (final c in await db.select(db.habitCompletions).get()) {
        perHabit.update(habits[c.habitId]!, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(perHabit, {'Meditar': 2, 'Leer': 1});

      final projects = {
        for (final p in await db.select(db.projects).get()) p.name: p,
      };
      expect(projects['Hijo']!.parentId, projects['Raíz']!.id);
      final task = await db.select(db.todoTasks).getSingle();
      expect(task.projectId, projects['Hijo']!.id);
      expect((await db.select(db.taskComments).getSingle()).taskId, task.id);

      final streak = await db.select(db.streaks).getSingle();
      expect(
        (await db.select(db.streakHistoryEntries).getSingle()).streakId,
        streak.id,
      );
      final exercise = await db.select(db.exercises).getSingle();
      expect(
        (await db.select(db.scheduledExercises).getSingle()).exerciseId,
        exercise.id,
      );
      final medication = await db.select(db.medications).getSingle();
      expect(
        (await db.select(db.medicationIntakes).getSingle()).medicationId,
        medication.id,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });

    test('exports what it restored as format 2 with the same UUIDs', () async {
      final repository = DriftBackupRepository(db);
      await repository.restore(parse(_formatOneFile()));
      final ids = (await db.select(db.habits).get()).map((h) => h.id).toSet();

      final exported = await repository.export();
      final reparsed = parse(exported.encode());

      expect(reparsed.format, 2);
      expect(reparsed.tables['habits']!.map((row) => row['id']).toSet(), ids);
    });
  });
}
