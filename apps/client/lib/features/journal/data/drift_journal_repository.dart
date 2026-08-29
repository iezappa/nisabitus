import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/journal_content.dart';
import '../domain/journal_repository.dart';

/// Drift-backed implementation of [JournalRepository].
class DriftJournalRepository implements JournalRepository {
  DriftJournalRepository(this._db);

  final AppDatabase _db;

  @override
  Future<JournalEntry?> forDay(DateTime day) async {
    final row = await (_db.select(
      _db.moodEntries,
    )..where((e) => e.date.equals(dateOnly(day)))).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<JournalEntry> save(DateTime day, JournalContent content) async {
    final date = dateOnly(day);

    // The unique index on the date turns this into an update rather than a
    // second entry for the same day.
    await _db
        .into(_db.moodEntries)
        .insert(
          MoodEntriesCompanion.insert(content: content.serialize(), date: date),
          onConflict: DoUpdate(
            (_) => MoodEntriesCompanion(content: Value(content.serialize())),
            target: [_db.moodEntries.date],
          ),
        );

    return (await forDay(date))!;
  }

  @override
  Future<void> deleteForDay(DateTime day) async {
    await (_db.delete(
      _db.moodEntries,
    )..where((e) => e.date.equals(dateOnly(day)))).go();
  }

  @override
  Future<JournalPage> history(
    DateRange range, {
    int page = 0,
    int pageSize = 5,
  }) async {
    final inRange = _db.moodEntries.date.isBetweenValues(
      range.start,
      range.end,
    );

    final counter = _db.moodEntries.id.count();
    final totalQuery = _db.selectOnly(_db.moodEntries)
      ..addColumns([counter])
      ..where(inRange);
    final total = (await totalQuery.getSingle()).read(counter) ?? 0;

    final rows =
        await (_db.select(_db.moodEntries)
              ..where((_) => inRange)
              ..orderBy([(e) => OrderingTerm.desc(e.date)])
              ..limit(pageSize, offset: page * pageSize))
            .get();

    return JournalPage(
      entries: rows.map(_toDomain).toList(),
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }

  JournalEntry _toDomain(MoodEntryRow row) => JournalEntry(
    id: row.id,
    date: row.date,
    content: JournalContent.parse(row.content),
  );
}
