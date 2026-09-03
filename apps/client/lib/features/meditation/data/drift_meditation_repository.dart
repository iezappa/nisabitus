import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/meditation.dart';
import '../domain/meditation_repository.dart';
import '../domain/meditation_stats.dart';

/// Drift-backed implementation of [MeditationRepository].
class DriftMeditationRepository implements MeditationRepository {
  DriftMeditationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<MeditationSession>> sessionsFor(DateTime day) async {
    final rows =
        await (_db.select(_db.meditationSessions)
              ..where((s) => s.date.equals(dateOnly(day)))
              ..orderBy([(s) => OrderingTerm.asc(s.id)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<DailyMeditation> dayFor(DateTime day) async =>
      DailyMeditation.from(await sessionsFor(day));

  @override
  Future<MeditationSession> add(DateTime day, MeditationDraft draft) async {
    final date = dateOnly(day);
    // Building the entity first lets the domain reject an impossible sitting
    // before anything is written.
    final validated = MeditationSession(
      id: 0,
      date: date,
      minutes: draft.minutes,
      note: draft.note,
    );

    final id = await _db
        .into(_db.meditationSessions)
        .insert(
          MeditationSessionsCompanion.insert(
            date: date,
            minutes: validated.minutes,
            note: Value(validated.note),
          ),
        );

    return validated.copyWith(id: id);
  }

  @override
  Future<MeditationSession> update(int id, MeditationDraft draft) async {
    final existing = await (_db.select(
      _db.meditationSessions,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw StateError('Meditation session $id was not found');
    }

    final validated = MeditationSession(
      id: id,
      date: existing.date,
      minutes: draft.minutes,
      note: draft.note,
    );

    await (_db.update(
      _db.meditationSessions,
    )..where((s) => s.id.equals(id))).write(
      MeditationSessionsCompanion(
        minutes: Value(validated.minutes),
        // An absent-or-null value rather than a skipped field: clearing a
        // note is a thing to be able to do.
        note: Value(validated.note),
      ),
    );

    return validated;
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(
      _db.meditationSessions,
    )..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<MeditationStats> statsFor(DateRange range) async {
    final rows = await (_db.select(
      _db.meditationSessions,
    )..where((s) => s.date.isBetweenValues(range.start, range.end))).get();

    return MeditationStats.from(range, rows.map(_toDomain).toList());
  }

  MeditationSession _toDomain(MeditationSessionRow row) => MeditationSession(
    id: row.id,
    date: row.date,
    minutes: row.minutes,
    note: row.note,
  );
}
