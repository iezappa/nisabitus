import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../domain/habit.dart';
import '../domain/habit_draft.dart';
import '../domain/habit_frequency.dart';
import '../domain/habit_repository.dart';
import '../../../core/time/weekday.dart';

/// Drift-backed implementation of [HabitRepository].
///
/// This is the only place in the module that knows habits live in SQLite.
class DriftHabitRepository implements HabitRepository {
  DriftHabitRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Habit>> listForDay(
    DateTime day, {
    HabitFrequency? frequency,
  }) async {
    final query = _db.select(_db.habits);
    if (frequency != null) {
      query.where((h) => h.frequency.equals(frequency.wireName));
    }
    final rows = await query.get();
    if (rows.isEmpty) return const [];

    // Each habit resolves against its own period, so the widest window that
    // can matter is the union of them all. One query covers every habit
    // instead of one query per habit.
    final periods = {
      for (final row in rows)
        row.id: HabitFrequency.parse(row.frequency).periodFor(day),
    };
    final earliest = periods.values
        .map((period) => period.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = periods.values
        .map((period) => period.end)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final completions =
        await (_db.select(_db.habitCompletions)..where(
              (c) =>
                  c.habitId.isIn(rows.map((row) => row.id)) &
                  c.completionDate.isBetweenValues(earliest, latest),
            ))
            .get();

    final fulfilled = <int>{
      for (final completion in completions)
        if (periods[completion.habitId]!.contains(completion.completionDate))
          completion.habitId,
    };

    return [
      for (final row in rows)
        _toDomain(row, completed: fulfilled.contains(row.id)),
    ];
  }

  @override
  Future<Habit> create(HabitDraft draft, {DateTime? on}) async {
    final today = dateOnly(on ?? DateTime.now());
    // Building the entity first means the domain rules reject bad input
    // before anything reaches the database.
    final validated = _fromDraft(draft, id: 0, createdAt: today);

    final id = await _db
        .into(_db.habits)
        .insert(
          _toCompanion(validated, createdAt: today, scheduledDate: today),
        );

    return _hydrate(id, today);
  }

  @override
  Future<Habit> update(int id, HabitDraft draft, {DateTime? on}) async {
    final existing = await _requireRow(id);
    final validated = _fromDraft(draft, id: id, createdAt: existing.createdAt);

    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      _toCompanion(
        validated,
        createdAt: existing.createdAt,
        scheduledDate: existing.scheduledDate,
      ),
    );

    return _hydrate(id, dateOnly(on ?? DateTime.now()));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();
  }

  @override
  Future<Habit> toggleCompletion(int id, DateTime day) async {
    final row = await _requireRow(id);
    final period = HabitFrequency.parse(row.frequency).periodFor(day);
    final removed = await _clearPeriod(id, period);

    if (removed == 0) {
      await _recordCompletion(id, day);
    }

    await _writeStatus(
      id,
      removed == 0 ? HabitStatus.done : HabitStatus.pending,
    );
    return _hydrate(id, day);
  }

  @override
  Future<Habit> changeStatus(int id, HabitStatus status, DateTime day) async {
    final row = await _requireRow(id);
    final period = HabitFrequency.parse(row.frequency).periodFor(day);

    if (status == HabitStatus.done) {
      if (await _countInPeriod(id, period) == 0) {
        await _recordCompletion(id, day);
      }
    } else {
      await _clearPeriod(id, period);
    }

    await _writeStatus(id, status);
    return _hydrate(id, day);
  }

  @override
  Future<List<DailyCompletionCount>> completionsPerDay(DateRange range) async {
    final rows =
        await (_db.select(_db.habitCompletions)..where(
              (c) => c.completionDate.isBetweenValues(range.start, range.end),
            ))
            .get();

    final perDay = <DateTime, int>{};
    for (final row in rows) {
      final day = dateOnly(row.completionDate);
      perDay[day] = (perDay[day] ?? 0) + 1;
    }

    final days = perDay.keys.toList()..sort();
    return [for (final day in days) (day: day, count: perDay[day]!)];
  }

  @override
  Future<int> totalCompletions(DateRange range) async {
    final count = _db.habitCompletions.id.count();
    final query = _db.selectOnly(_db.habitCompletions)
      ..addColumns([count])
      ..where(
        _db.habitCompletions.completionDate.isBetweenValues(
          range.start,
          range.end,
        ),
      );

    return (await query.getSingle()).read(count) ?? 0;
  }

  @override
  Future<int> countHabits() async {
    final count = _db.habits.id.count();
    final query = _db.selectOnly(_db.habits)..addColumns([count]);

    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<HabitRow> _requireRow(int id) async {
    final row = await (_db.select(
      _db.habits,
    )..where((h) => h.id.equals(id))).getSingleOrNull();

    if (row == null) {
      throw StateError('Habit $id was not found');
    }
    return row;
  }

  Future<Habit> _hydrate(int id, DateTime day) async {
    final row = await _requireRow(id);
    final period = HabitFrequency.parse(row.frequency).periodFor(day);
    final completed = await _countInPeriod(id, period) > 0;

    return _toDomain(row, completed: completed);
  }

  Future<int> _countInPeriod(int id, DateRange period) async {
    final rows =
        await (_db.select(_db.habitCompletions)..where(
              (c) =>
                  c.habitId.equals(id) &
                  c.completionDate.isBetweenValues(period.start, period.end),
            ))
            .get();

    return rows.length;
  }

  Future<int> _clearPeriod(int id, DateRange period) =>
      (_db.delete(_db.habitCompletions)..where(
            (c) =>
                c.habitId.equals(id) &
                c.completionDate.isBetweenValues(period.start, period.end),
          ))
          .go();

  Future<void> _recordCompletion(int id, DateTime day) async {
    await _db
        .into(_db.habitCompletions)
        .insert(
          HabitCompletionsCompanion.insert(
            habitId: id,
            completionDate: dateOnly(day),
          ),
        );
  }

  Future<void> _writeStatus(int id, HabitStatus status) async {
    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(status: Value(status.wireName)),
    );
  }

  Habit _fromDraft(
    HabitDraft draft, {
    required int id,
    required DateTime createdAt,
  }) => Habit(
    id: id,
    name: draft.name,
    description: draft.description,
    category: draft.category,
    frequency: draft.frequency,
    targetCount: draft.targetCount,
    endDate: draft.endDate,
    repeatForever: draft.repeatForever,
    repeatDays: draft.repeatDays,
    type: draft.type,
    status: HabitStatus.pending,
    createdAt: createdAt,
    scheduledDate: createdAt,
  );

  HabitsCompanion _toCompanion(
    Habit habit, {
    required DateTime createdAt,
    required DateTime scheduledDate,
  }) => HabitsCompanion.insert(
    name: habit.name,
    description: Value(habit.description),
    category: Value(habit.category),
    frequency: habit.frequency.wireName,
    targetCount: Value(habit.targetCount),
    endDate: Value(habit.endDate),
    repeatForever: Value(habit.repeatForever),
    repeatDays: Value(Weekday.encode(habit.repeatDays)),
    type: Value(habit.type),
    status: habit.status.wireName,
    createdAt: createdAt,
    scheduledDate: scheduledDate,
  );

  Habit _toDomain(HabitRow row, {required bool completed}) {
    final stored = HabitStatus.parse(row.status);
    // A habit is done for the day when the period holds a completion; a
    // cancelled habit stays cancelled until the user reverts it.
    final resolved = completed
        ? HabitStatus.done
        : stored == HabitStatus.cancelled
        ? HabitStatus.cancelled
        : HabitStatus.pending;

    return Habit(
      id: row.id,
      name: row.name,
      description: row.description,
      category: row.category,
      frequency: HabitFrequency.parse(row.frequency),
      targetCount: row.targetCount,
      endDate: row.endDate,
      repeatForever: row.repeatForever,
      repeatDays: Weekday.decode(row.repeatDays),
      type: row.type,
      status: resolved,
      createdAt: row.createdAt,
      scheduledDate: row.scheduledDate,
      completed: completed,
    );
  }
}
