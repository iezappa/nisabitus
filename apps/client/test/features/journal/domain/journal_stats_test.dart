import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/time/date_range.dart';
import 'package:nisabit/features/journal/domain/journal_stats.dart';

void main() {
  final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 12));

  group('JournalStats', () {
    test('reads as empty when nothing was written', () {
      final stats = JournalStats.from(range, const []);

      expect(stats.isEmpty, isTrue);
      expect(stats.entries, 0);
      expect(stats.coveragePercent, 0);
    });

    test('counts the entries of the window', () {
      final stats = JournalStats.from(range, [
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 11),
      ]);

      expect(stats.entries, 2);
    });

    test('reports coverage as the share of days written', () {
      final stats = JournalStats.from(range, [
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 11),
      ]);

      expect(stats.coveragePercent, 50);
    });

    test('reports the longest run of consecutive days written', () {
      final stats = JournalStats.from(range, [
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 11),
        DateTime(2026, 3, 12),
      ]);

      expect(stats.longestRun, 2);
    });

    test('plots a written or not written point for every day', () {
      final stats = JournalStats.from(range, [DateTime(2026, 3, 11)]);

      expect(stats.perDay, hasLength(range.dayCount));
      expect(stats.perDay.first.value, 0);
      expect(stats.perDay[2].value, 1);
    });

    test('ignores entries outside the window', () {
      final stats = JournalStats.from(range, [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 9),
      ]);

      expect(stats.entries, 1);
    });
  });
}
