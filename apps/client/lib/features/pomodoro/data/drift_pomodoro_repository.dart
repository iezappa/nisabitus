import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/pomodoro_draft.dart';
import '../domain/pomodoro_repository.dart';
import '../domain/pomodoro_session.dart';
import '../domain/pomodoro_stats.dart';

/// Drift-backed implementation of [PomodoroRepository].
class DriftPomodoroRepository implements PomodoroRepository {
  DriftPomodoroRepository(this._db);

  final AppDatabase _db;

  @override
  Future<PomodoroPage> list({int page = 0, int pageSize = 5}) async {
    final counter = _db.pomodoroSessions.id.count();
    final total =
        (await (_db.selectOnly(_db.pomodoroSessions)..addColumns([counter]))
                .getSingle())
            .read(counter) ??
        0;

    final rows =
        await (_db.select(_db.pomodoroSessions)
              ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
              ..limit(pageSize, offset: page * pageSize))
            .get();

    return PomodoroPage(
      sessions: rows.map(_toDomain).toList(),
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PomodoroSession?> byId(int id) async {
    final row = await (_db.select(
      _db.pomodoroSessions,
    )..where((s) => s.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<PomodoroSession> create(
    PomodoroDraft draft, {
    DateTime? startedAt,
  }) async {
    final begins = startedAt ?? DateTime.now();
    // Building the entity first lets the domain reject bad input before
    // anything reaches the database.
    final validated = _fromDraft(draft, id: 0, startedAt: begins);

    final id = await _db
        .into(_db.pomodoroSessions)
        .insert(
          PomodoroSessionsCompanion.insert(
            name: validated.name,
            category: Value(validated.category),
            purpose: Value(validated.purpose),
            cycles: Value(validated.cycles),
            focusDuration: Value(validated.focusDuration),
            breakDuration: Value(validated.breakDuration),
            completedCycles: const Value(0),
            status: PomodoroStatus.pending.wireName,
            startedAt: begins,
          ),
        );

    return (await byId(id))!;
  }

  @override
  Future<PomodoroSession> update(int id, PomodoroDraft draft) async {
    final existing = await _require(id);
    final validated = _fromDraft(draft, id: id, startedAt: existing.startedAt);

    await (_db.update(_db.pomodoroSessions)..where((s) => s.id.equals(id)))
        .write(
          PomodoroSessionsCompanion(
            name: Value(validated.name),
            category: Value(validated.category),
            purpose: Value(validated.purpose),
            cycles: Value(validated.cycles),
            focusDuration: Value(validated.focusDuration),
            breakDuration: Value(validated.breakDuration),
          ),
        );

    return (await byId(id))!;
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(
      _db.pomodoroSessions,
    )..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<PomodoroSession> completeCycle(int id) =>
      _apply(id, (session) => session.completeCycle());

  @override
  Future<PomodoroSession> finish(int id) =>
      _apply(id, (session) => session.finish());

  @override
  Future<PomodoroSession> cancel(int id) =>
      _apply(id, (session) => session.cancel());

  @override
  Future<PomodoroSession> setStatus(int id, PomodoroStatus status) =>
      _apply(id, (session) => session.copyWith(status: status));

  @override
  Future<PomodoroStats> statsFor(DateRange range) async {
    // The window is compared against startedAt, and the range's end is a day,
    // so it has to reach the end of that day rather than its midnight.
    final rows =
        await (_db.select(_db.pomodoroSessions)..where(
              (s) => s.startedAt.isBetweenValues(
                range.start,
                range.end.add(const Duration(days: 1)),
              ),
            ))
            .get();

    return PomodoroStats.from(rows.map(_toDomain).toList());
  }

  Future<PomodoroSession> _apply(
    int id,
    PomodoroSession Function(PomodoroSession) change,
  ) async {
    final updated = change(await _require(id));

    await (_db.update(_db.pomodoroSessions)..where((s) => s.id.equals(id)))
        .write(
          PomodoroSessionsCompanion(
            completedCycles: Value(updated.completedCycles),
            status: Value(updated.status.wireName),
          ),
        );

    return updated;
  }

  Future<PomodoroSession> _require(int id) async {
    final session = await byId(id);
    if (session == null) {
      throw StateError('Pomodoro session $id was not found');
    }
    return session;
  }

  PomodoroSession _fromDraft(
    PomodoroDraft draft, {
    required int id,
    required DateTime startedAt,
  }) => PomodoroSession(
    id: id,
    name: draft.name,
    category: draft.category,
    purpose: draft.purpose,
    cycles: draft.cycles,
    focusDuration: draft.focusDuration,
    breakDuration: draft.breakDuration,
    completedCycles: 0,
    status: PomodoroStatus.pending,
    startedAt: startedAt,
  );

  PomodoroSession _toDomain(PomodoroSessionRow row) => PomodoroSession(
    id: row.id,
    name: row.name,
    category: row.category,
    purpose: row.purpose,
    cycles: row.cycles,
    focusDuration: row.focusDuration,
    breakDuration: row.breakDuration,
    completedCycles: row.completedCycles,
    status: PomodoroStatus.parse(row.status),
    startedAt: row.startedAt,
  );
}
