import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';

/// Counts everything the user recorded, day by day.
///
/// One row per thing written down, from every module that records anything at
/// all, read in a single query rather than thirteen: the grid asks about six
/// months at once and a round trip per table would be thirteen of them.
///
/// What counts is what the user **did**, not what the app planned for them. A
/// scheduled exercise counts once it is ticked; a habit counts when it is
/// completed, not when it comes round; a task counts on the day it was
/// finished. Anything else would fill the grid with squares nobody earned.
class ActivityCounts {
  ActivityCounts(this._db);

  final AppDatabase _db;

  /// Every table that records something, and the column that says when.
  ///
  /// Listed here rather than derived, because "when did this happen" is not
  /// something a table can be asked in general: `date` on a water entry is
  /// the day it was drunk, `completed_at` on a task is the moment it was
  /// finished, and `scheduled_date` on an exercise only means anything once
  /// `completed` is true. A table added to the app and not added here is a
  /// module the grid is blind to — which the test against `allTables` is
  /// there to catch.
  static const _sources = <({String table, String column, String? filter})>[
    (table: 'habit_completions', column: 'completion_date', filter: null),
    (table: 'streak_history_entries', column: 'reached_at', filter: null),
    (table: 'sleep_logs', column: 'date', filter: null),
    (table: 'mood_entries', column: 'date', filter: null),
    (table: 'pomodoro_sessions', column: 'started_at', filter: null),
    (
      table: 'todo_tasks',
      column: 'completed_at',
      filter: '"completed_at" IS NOT NULL',
    ),
    (table: 'food_entries', column: 'date', filter: null),
    (table: 'water_entries', column: 'date', filter: null),
    (table: 'meditation_sessions', column: 'date', filter: null),
    (table: 'medication_intakes', column: 'date', filter: null),
    (table: 'step_logs', column: 'date', filter: null),
    (
      table: 'scheduled_exercises',
      column: 'scheduled_date',
      filter: '"completed" = 1',
    ),
    (
      table: 'disciplines',
      column: 'scheduled_date',
      filter: '"completed" = 1',
    ),
  ];

  /// The tables the grid deliberately leaves out, and why.
  ///
  /// Read by the test that holds [_sources] against the database, so a new
  /// table has to be named in one list or the other rather than forgotten.
  static const ignored = <String>{
    // Catalogues and settings: describing a thing is not doing it.
    'habits', 'streaks', 'projects', 'board_columns', 'exercises',
    'medications', 'foods', 'nutrition_goals', 'hydration_goals', 'step_goals',
    // Parts of something already counted once, through its parent.
    'task_comments', 'task_checklist_items', 'food_entry_items',
  };

  /// How many things were recorded on each day of [range].
  ///
  /// Keyed by the day at local midnight. A day with nothing recorded is
  /// absent rather than zero: the caller draws an empty square either way,
  /// and a map of every silent day would be a map that says nothing.
  Future<Map<DateTime, int>> perDay(DateRange range) async {
    final from = dateOnly(range.start);
    // The whole of the last day, not the instant it began: `completed_at` and
    // `started_at` are moments, and a task finished at nine in the evening
    // must land on that day rather than off the end of the window.
    final until = DateTime(range.end.year, range.end.month, range.end.day + 1);

    final union = _sources
        .map(
          (source) =>
              'SELECT "${source.column}" AS at FROM "${source.table}" '
              'WHERE "${source.column}" >= ? AND "${source.column}" < ?'
              '${source.filter == null ? '' : ' AND ${source.filter}'}',
        )
        .join(' UNION ALL ');

    final rows = await _db
        .customSelect(
          union,
          variables: [
            for (var i = 0; i < _sources.length; i++) ...[
              Variable<DateTime>(from),
              Variable<DateTime>(until),
            ],
          ],
        )
        .get();

    final counts = <DateTime, int>{};
    for (final row in rows) {
      // Floored in Dart rather than in SQL: `date(x, 'unixepoch')` reads the
      // stamp as UTC, and a day here is the user's own midnight — so an
      // evening entry would slide into tomorrow for anyone west of London.
      final day = dateOnly(row.read<DateTime>('at'));
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return counts;
  }

  /// The table names the grid reads, for the test that guards the list.
  static Set<String> get countedTables =>
      {for (final source in _sources) source.table};
}
