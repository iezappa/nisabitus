import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/streak.dart';
import '../domain/streak_repository.dart';

/// Drift-backed implementation of [StreakRepository].
class DriftStreakRepository implements StreakRepository {
  DriftStreakRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Streak>> list() async {
    final rows = await (_db.select(
      _db.streaks,
    )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<Streak> create(String name, {DateTime? on}) async {
    final today = dateOnly(on ?? DateTime.now());
    // Building the entity first lets the domain reject a blank name before
    // anything is written.
    final validated = Streak.create(id: 0, name: name, createdAt: today);

    final id = await _db
        .into(_db.streaks)
        .insert(
          StreaksCompanion.insert(
            name: validated.name,
            count: Value(validated.count),
            maxStreak: Value(validated.maxStreak),
            lastUpdated: validated.lastUpdated,
          ),
        );

    return _require(id);
  }

  @override
  Future<Streak> rename(int id, String name) async {
    final renamed = (await _require(id)).rename(name);
    await _write(renamed);

    return renamed;
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.streaks)..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<Streak> increment(int id, {DateTime? on}) async {
    final today = dateOnly(on ?? DateTime.now());
    final incremented = (await _require(id)).increment(today);

    // The counter and its history point are one fact, so they are written
    // together or not at all.
    await _db.transaction(() async {
      await _write(incremented);
      await _db
          .into(_db.streakHistoryEntries)
          .insert(
            StreakHistoryEntriesCompanion.insert(
              streakId: id,
              count: incremented.count,
              reachedAt: today,
            ),
          );
    });

    return incremented;
  }

  @override
  Future<Streak> reset(int id, {DateTime? on}) async {
    final reset = (await _require(id)).reset(dateOnly(on ?? DateTime.now()));
    await _write(reset);

    return reset;
  }

  @override
  Future<List<StreakPoint>> historyFor(int id) async {
    final rows =
        await (_db.select(_db.streakHistoryEntries)
              ..where((h) => h.streakId.equals(id))
              ..orderBy([(h) => OrderingTerm.asc(h.reachedAt)]))
            .get();

    return [
      for (final row in rows) (day: dateOnly(row.reachedAt), count: row.count),
    ];
  }

  @override
  Future<List<StreakSeries>> chartSeries(DateRange range) async {
    final streaks = await (_db.select(
      _db.streaks,
    )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    if (streaks.isEmpty) return const [];

    final history =
        await (_db.select(_db.streakHistoryEntries)..where(
              (h) => h.reachedAt.isBetweenValues(range.start, range.end),
            ))
            .get();

    // Several increments can land on the same day; the line should show the
    // value the day ended on, so the highest wins.
    final highestPerDay = <int, Map<DateTime, int>>{};
    for (final row in history) {
      final perDay = highestPerDay.putIfAbsent(row.streakId, () => {});
      final day = dateOnly(row.reachedAt);
      final current = perDay[day];
      if (current == null || row.count > current) {
        perDay[day] = row.count;
      }
    }

    final series = <StreakSeries>[];
    for (final streak in streaks) {
      final perDay = highestPerDay[streak.id];
      if (perDay == null || perDay.isEmpty) continue;

      final days = perDay.keys.toList()..sort();
      series.add(
        StreakSeries(
          streakId: streak.id,
          name: streak.name,
          points: [for (final day in days) (day: day, count: perDay[day]!)],
        ),
      );
    }

    return series;
  }

  Future<Streak> _require(int id) async {
    final row = await (_db.select(
      _db.streaks,
    )..where((s) => s.id.equals(id))).getSingleOrNull();

    if (row == null) {
      throw StateError('Streak $id was not found');
    }
    return _toDomain(row);
  }

  Future<void> _write(Streak streak) async {
    await (_db.update(_db.streaks)..where((s) => s.id.equals(streak.id))).write(
      StreaksCompanion(
        name: Value(streak.name),
        count: Value(streak.count),
        maxStreak: Value(streak.maxStreak),
        lastUpdated: Value(streak.lastUpdated),
      ),
    );
  }

  Streak _toDomain(StreakRow row) => Streak(
    id: row.id,
    name: row.name,
    count: row.count,
    maxStreak: row.maxStreak,
    lastUpdated: row.lastUpdated,
  );
}
