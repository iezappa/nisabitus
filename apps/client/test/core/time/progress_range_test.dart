import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/time/progress_range.dart';

void main() {
  final today = DateTime(2026, 3, 30);

  group('ProgressRange.toDateRange', () {
    test('day covers only today', () {
      final range = ProgressRange.day.toDateRange(from: today);

      expect(range.start, today);
      expect(range.end, today);
      expect(range.dayCount, 1);
    });

    test('week covers the last seven days including today', () {
      final range = ProgressRange.week.toDateRange(from: today);

      expect(range.start, DateTime(2026, 3, 24));
      expect(range.end, today);
      expect(range.dayCount, 7);
    });

    test('month covers the last thirty days, the default window', () {
      final range = ProgressRange.month.toDateRange(from: today);

      expect(range.start, DateTime(2026, 3, 1));
      expect(range.dayCount, 30);
    });

    test('year covers the last three hundred and sixty five days', () {
      final range = ProgressRange.year.toDateRange(from: today);

      expect(range.dayCount, 365);
      expect(range.end, today);
    });

    test('ignores the time component of the reference day', () {
      final range = ProgressRange.day.toDateRange(
        from: DateTime(2026, 3, 30, 23, 45),
      );

      expect(range.start, today);
    });

    test('month is the default range', () {
      expect(ProgressRange.defaultRange, ProgressRange.month);
    });
  });
}
