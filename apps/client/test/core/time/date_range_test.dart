import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/core/time/date_range.dart';

void main() {
  group('DateRange', () {
    test('normalizes bounds to date-only', () {
      final range = DateRange(
        DateTime(2026, 3, 10, 14, 32, 5),
        DateTime(2026, 3, 15, 23, 59, 59),
      );

      expect(range.start, DateTime(2026, 3, 10));
      expect(range.end, DateTime(2026, 3, 15));
    });

    test('contains both bounds', () {
      final range = DateRange(DateTime(2026, 3, 10), DateTime(2026, 3, 15));

      expect(range.contains(DateTime(2026, 3, 10)), isTrue);
      expect(range.contains(DateTime(2026, 3, 15)), isTrue);
      expect(range.contains(DateTime(2026, 3, 12)), isTrue);
    });

    test('ignores the time component when testing containment', () {
      final range = DateRange(DateTime(2026, 3, 10), DateTime(2026, 3, 10));

      expect(range.contains(DateTime(2026, 3, 10, 23, 59)), isTrue);
    });

    test('excludes days outside the bounds', () {
      final range = DateRange(DateTime(2026, 3, 10), DateTime(2026, 3, 15));

      expect(range.contains(DateTime(2026, 3, 9)), isFalse);
      expect(range.contains(DateTime(2026, 3, 16)), isFalse);
    });

    test('rejects a start later than the end', () {
      expect(
        () => DateRange(DateTime(2026, 3, 15), DateTime(2026, 3, 10)),
        throwsArgumentError,
      );
    });

    test('lastDays builds an inclusive window ending on the given day', () {
      final range = DateRange.lastDays(30, from: DateTime(2026, 3, 30));

      expect(range.start, DateTime(2026, 3, 1));
      expect(range.end, DateTime(2026, 3, 30));
      expect(range.dayCount, 30);
    });
  });
}
