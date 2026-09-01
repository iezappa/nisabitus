import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_journal_repository.dart';
import '../domain/journal_content.dart';
import '../domain/journal_repository.dart';
import '../domain/journal_stats.dart';

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => DriftJournalRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final journalRevisionProvider = StateProvider<int>((ref) => 0);

/// The window both the progress figures and the history pager look at.
///
/// One window, one control: the chart and the list of past entries answer
/// the same question, so letting them drift apart only confuses.
final journalProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The figures behind the progress view, for the chosen window.
final journalStatsProvider = FutureProvider<JournalStats>((ref) {
  ref.watch(journalRevisionProvider);

  final range = ref
      .watch(journalProgressRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref.watch(journalRepositoryProvider).statsFor(range);
});

/// Zero-based page of the history list.
final journalHistoryPageProvider = StateProvider<int>((ref) => 0);

final journalForSelectedDayProvider = FutureProvider<JournalEntry?>((ref) {
  ref.watch(journalRevisionProvider);

  return ref
      .watch(journalRepositoryProvider)
      .forDay(ref.watch(selectedDayProvider));
});

final journalHistoryProvider = FutureProvider<JournalPage>((ref) {
  ref.watch(journalRevisionProvider);
  // The spec reloads the history when the active day changes too.
  ref.watch(selectedDayProvider);

  final range = ref
      .watch(journalProgressRangeProvider)
      .toDateRange(from: ref.watch(todayProvider));

  return ref
      .watch(journalRepositoryProvider)
      .history(range, page: ref.watch(journalHistoryPageProvider));
});

/// Write operations, kept out of the widgets.
class JournalActions {
  JournalActions(this._ref);

  final Ref _ref;

  Future<void> save(JournalContent content) async {
    await _ref
        .read(journalRepositoryProvider)
        .save(_ref.read(selectedDayProvider), content);
    _invalidate();
  }

  Future<void> delete() async {
    await _ref
        .read(journalRepositoryProvider)
        .deleteForDay(_ref.read(selectedDayProvider));
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(journalRevisionProvider.notifier).update((value) => value + 1);
}

final journalActionsProvider = Provider<JournalActions>(JournalActions.new);
