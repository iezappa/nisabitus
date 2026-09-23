import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/backup/domain/auto_backup.dart';

void main() {
  final monday = DateTime(2026, 9, 7, 9);

  group('whether a copy is owed', () {
    test('is yes the first time, rather than a week from now', () {
      // The point of switching it on is knowing that it works.
      expect(autoBackupDue(now: monday, lastRunAt: null), isTrue);
    });

    test('is no until the week is up', () {
      expect(
        autoBackupDue(
          now: monday.add(const Duration(days: 6, hours: 23)),
          lastRunAt: monday,
        ),
        isFalse,
      );
    });

    test('is yes once it is', () {
      expect(
        autoBackupDue(
          now: monday.add(const Duration(days: 7)),
          lastRunAt: monday,
        ),
        isTrue,
      );
    });

    test('is yes when the clock has gone backwards', () {
      // A device whose date was wrong and has been corrected. A copy stamped
      // in the future would otherwise hold the whole feature off until that
      // date came round.
      expect(autoBackupDue(now: monday, lastRunAt: DateTime(2030)), isTrue);
    });
  });

  group('what the file is called', () {
    test('carries the day, so a folder ends up holding a history', () {
      expect(
        autoBackupFileName(DateTime(2026, 9, 7, 23, 40)),
        'nisabit-2026-09-07.json',
      );
    });

    test('pads, so a listing sorts by name into date order', () {
      expect(
        autoBackupFileName(DateTime(2026, 1, 5)),
        'nisabit-2026-01-05.json',
      );
    });
  });
}
