import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/weekday.dart';
import '../../exercise/domain/scheduled_exercise.dart';
import '../domain/discipline.dart';
import '../domain/discipline_repository.dart';

/// Drift-backed implementation of [DisciplineRepository].
class DriftDisciplineRepository implements DisciplineRepository {
  DriftDisciplineRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Discipline>> forDay(DateTime day) async {
    final rows =
        await (_db.select(_db.disciplines)
              ..where((d) => d.scheduledDate.equals(dateOnly(day)))
              ..orderBy([(d) => OrderingTerm.asc(d.id)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<Discipline> schedule(
    DateTime day,
    DisciplineDraft draft, {
    ExerciseRecurrence? recurrence,
  }) async {
    final date = dateOnly(day);
    final groupId = recurrence == null ? null : _mintGroupId(date);

    // Built first so the domain rejects an impossible session before a
    // hundred copies of it reach the database.
    final validated = Discipline(
      id: 0,
      name: draft.name,
      scheduledDate: date,
      durationMinutes: draft.durationMinutes,
      distanceKm: draft.distanceKm,
      notes: draft.notes,
      recurrenceGroupId: groupId,
      repeatDays: recurrence?.days ?? const {},
      repeatForever: recurrence?.type == RecurrenceType.forever,
    );

    // Worked out before the transaction, so a bad recurrence throws without
    // leaving the first day behind on its own.
    final copies = recurrence?.daysAfter(date) ?? const <DateTime>[];

    return _db.transaction(() async {
      final id = await _insert(validated);
      for (final copy in copies) {
        await _insert(validated.copyWith(scheduledDate: copy));
      }

      return validated.copyWith(id: id);
    });
  }

  @override
  Future<Discipline> update(int id, DisciplineDraft draft) async {
    final existing = await _byId(id);
    if (existing == null) throw StateError('Discipline $id was not found');

    final validated = Discipline(
      id: id,
      name: draft.name,
      scheduledDate: existing.scheduledDate,
      durationMinutes: draft.durationMinutes,
      distanceKm: draft.distanceKm,
      notes: draft.notes,
      feedback: existing.feedback,
      completed: existing.completed,
      recurrenceGroupId: existing.recurrenceGroupId,
      repeatDays: existing.repeatDays,
      repeatForever: existing.repeatForever,
    );

    // This day only. The other days of the series are their own rows.
    await (_db.update(_db.disciplines)..where((d) => d.id.equals(id))).write(
      DisciplinesCompanion(
        name: Value(validated.name),
        durationMinutes: Value(validated.durationMinutes),
        distanceKm: Value(validated.distanceKm),
        notes: Value(validated.notes),
      ),
    );

    return validated;
  }

  @override
  Future<Discipline> complete(int id, DisciplineCompletion completion) async {
    final existing = await _byId(id);
    if (existing == null) throw StateError('Discipline $id was not found');

    // What was planned stands until something is said instead.
    final validated = Discipline(
      id: id,
      name: existing.name,
      scheduledDate: existing.scheduledDate,
      durationMinutes: completion.durationMinutes ?? existing.durationMinutes,
      distanceKm: completion.distanceKm ?? existing.distanceKm,
      notes: existing.notes,
      feedback: completion.feedback ?? existing.feedback,
      completed: true,
      recurrenceGroupId: existing.recurrenceGroupId,
      repeatDays: existing.repeatDays,
      repeatForever: existing.repeatForever,
    );

    await (_db.update(_db.disciplines)..where((d) => d.id.equals(id))).write(
      DisciplinesCompanion(
        completed: const Value(true),
        durationMinutes: Value(validated.durationMinutes),
        distanceKm: Value(validated.distanceKm),
        feedback: Value(validated.feedback),
      ),
    );

    return validated;
  }

  @override
  Future<Discipline> reopen(int id) async {
    final existing = await _byId(id);
    if (existing == null) throw StateError('Discipline $id was not found');

    // The feedback stays: un-ticking says it is not finished, not that it
    // never happened.
    await (_db.update(_db.disciplines)..where((d) => d.id.equals(id))).write(
      const DisciplinesCompanion(completed: Value(false)),
    );

    return existing.copyWith(completed: false);
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.disciplines)..where((d) => d.id.equals(id))).go();
  }

  @override
  Future<void> stopRecurrence(int id) async {
    final existing = await _byId(id);
    if (existing == null) throw StateError('Discipline $id was not found');

    final groupId = existing.recurrenceGroupId;
    if (groupId == null || groupId.isEmpty) {
      throw StateError('Discipline $id is not part of a repetition');
    }

    await _db.transaction(() async {
      // Later, and not done. A day already practised stays on the record.
      await (_db.delete(_db.disciplines)..where(
            (d) =>
                d.recurrenceGroupId.equals(groupId) &
                d.scheduledDate.isBiggerThanValue(existing.scheduledDate) &
                d.completed.equals(false),
          ))
          .go();

      await (_db.update(_db.disciplines)
            ..where((d) => d.recurrenceGroupId.equals(groupId)))
          .write(const DisciplinesCompanion(repeatForever: Value(false)));
    });
  }

  Future<int> _insert(Discipline discipline) => _db
      .into(_db.disciplines)
      .insert(
        DisciplinesCompanion.insert(
          name: discipline.name,
          scheduledDate: discipline.scheduledDate,
          durationMinutes: discipline.durationMinutes,
          distanceKm: Value(discipline.distanceKm),
          notes: Value(discipline.notes),
          feedback: Value(discipline.feedback),
          completed: Value(discipline.completed),
          recurrenceGroupId: Value(discipline.recurrenceGroupId),
          repeatDays: Value(Weekday.encode(discipline.repeatDays)),
          repeatForever: Value(discipline.repeatForever),
        ),
      );

  Future<Discipline?> _byId(int id) async {
    final row = await (_db.select(
      _db.disciplines,
    )..where((d) => d.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  /// The same key shape the scheduled exercises use: one user, one device,
  /// no sync to collide with.
  String _mintGroupId(DateTime day) =>
      '${day.toIso8601String().substring(0, 10)}'
      '-${DateTime.now().microsecondsSinceEpoch}';

  Discipline _toDomain(DisciplineRow row) => Discipline(
    id: row.id,
    name: row.name,
    scheduledDate: row.scheduledDate,
    durationMinutes: row.durationMinutes,
    distanceKm: row.distanceKm,
    notes: row.notes,
    feedback: row.feedback,
    completed: row.completed,
    recurrenceGroupId: row.recurrenceGroupId,
    repeatDays: Weekday.decode(row.repeatDays),
    repeatForever: row.repeatForever,
  );
}
