import '../../../core/time/date_range.dart';
import 'journal_content.dart';

/// One day's journal entry, with its fields already parsed.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.content,
  });

  final int id;
  final DateTime date;
  final JournalContent content;
}

/// A slice of the history, with enough context to render the pager.
class JournalPage {
  const JournalPage({
    required this.entries,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<JournalEntry> entries;

  /// How many entries the window holds in total, not just this page.
  final int total;

  /// Zero-based.
  final int page;
  final int pageSize;

  int get pageCount => (total / pageSize).ceil();
}

/// The port the journal module talks to.
abstract interface class JournalRepository {
  /// The entry written for [day], or null if there is none.
  Future<JournalEntry?> forDay(DateTime day);

  /// Writes or replaces the entry for [day]. One entry per day.
  Future<JournalEntry> save(DateTime day, JournalContent content);

  Future<void> deleteForDay(DateTime day);

  /// Past entries inside [range], newest first, five to a page.
  Future<JournalPage> history(DateRange range, {int page, int pageSize});
}
