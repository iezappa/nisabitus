import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/pomodoro/data/drift_pomodoro_repository.dart';
import 'package:nisabitus/features/pomodoro/domain/pomodoro_draft.dart';
import 'package:nisabitus/features/pomodoro/domain/pomodoro_repository.dart';
import 'package:nisabitus/features/pomodoro/domain/pomodoro_session.dart';

void main() {
  late AppDatabase db;
  late PomodoroRepository repository;

  final march = DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
  final start = DateTime(2026, 3, 11, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftPomodoroRepository(db);
  });
  tearDown(() => db.close());

  Future<PomodoroSession> create({
    String name = 'Escribir',
    String? category,
    int cycles = 4,
    int focusDuration = 25,
    DateTime? startedAt,
  }) => repository.create(
    PomodoroDraft(
      name: name,
      category: category,
      cycles: cycles,
      focusDuration: focusDuration,
      breakDuration: 5,
    ),
    startedAt: startedAt ?? start,
  );

  group('create', () {
    test('stores a pending session with no cycles served', () async {
      final session = await create();

      expect(session.name, 'Escribir');
      expect(session.status, PomodoroStatus.pending);
      expect(session.completedCycles, 0);
      expect(session.progress, SessionProgress.pending);
    });

    test('rejects a blank name', () {
      expect(
        () => repository.create(
          const PomodoroDraft(name: '  '),
          startedAt: start,
        ),
        throwsArgumentError,
      );
    });

    test('rejects cycles outside the allowed range', () {
      expect(
        () => repository.create(
          const PomodoroDraft(name: 'X', cycles: 0),
          startedAt: start,
        ),
        throwsArgumentError,
      );
    });
  });

  group('list', () {
    test('is empty at first', () async {
      final page = await repository.list();

      expect(page.sessions, isEmpty);
      expect(page.pageCount, 0);
    });

    test('serves five to a page, newest first', () async {
      for (var i = 1; i <= 7; i++) {
        await create(name: 'Sesión $i', startedAt: start.add(Duration(days: i)));
      }

      final first = await repository.list();
      final second = await repository.list(page: 1);

      expect(first.sessions, hasLength(5));
      expect(first.sessions.first.name, 'Sesión 7');
      expect(first.total, 7);
      expect(second.sessions, hasLength(2));
    });
  });

  group('cycles', () {
    test('completing one advances the count', () async {
      final session = await create();

      final after = await repository.completeCycle(session.id);

      expect(after.completedCycles, 1);
      expect(after.progress, SessionProgress.inProgress);
    });

    test('completing the last one closes the session', () async {
      final session = await create(cycles: 2);
      await repository.completeCycle(session.id);

      final after = await repository.completeCycle(session.id);

      expect(after.status, PomodoroStatus.completed);
      expect(after.progress, SessionProgress.completed);
    });

    test('never runs past the planned cycles', () async {
      final session = await create(cycles: 1);
      await repository.completeCycle(session.id);

      final after = await repository.completeCycle(session.id);

      expect(after.completedCycles, 1);
    });
  });

  group('finish and cancel', () {
    test('finishing serves every remaining cycle', () async {
      final session = await create(cycles: 4);

      final after = await repository.finish(session.id);

      expect(after.completedCycles, 4);
      expect(after.status, PomodoroStatus.completed);
    });

    test('cancelling keeps what was already served', () async {
      final session = await create();
      await repository.completeCycle(session.id);

      final after = await repository.cancel(session.id);

      expect(after.status, PomodoroStatus.cancelled);
      expect(after.completedCycles, 1);
      expect(after.progress, SessionProgress.cancelled);
    });
  });

  group('delete', () {
    test('removes the session', () async {
      final session = await create();

      await repository.delete(session.id);

      expect((await repository.list()).sessions, isEmpty);
    });
  });

  group('statsFor', () {
    test('is empty when no cycle was served', () async {
      await create();

      expect((await repository.statsFor(march)).isEmpty, isTrue);
    });

    test('adds up the minutes served in the window', () async {
      final a = await create(category: 'Trabajo', focusDuration: 25);
      await repository.completeCycle(a.id);
      await repository.completeCycle(a.id);

      final stats = await repository.statsFor(march);

      expect(stats.focusMinutes, 50);
      expect(stats.cycles, 2);
      expect(stats.byCategory, {'Trabajo': 50});
    });

    test('leaves out sessions started outside the window', () async {
      final old = await create(startedAt: DateTime(2026, 1, 5, 9));
      await repository.completeCycle(old.id);

      expect((await repository.statsFor(march)).isEmpty, isTrue);
    });
  });
}
