import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/backup/domain/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 9, 16, 10);

  BackupReminder decide({
    DateTime? lastExportAt,
    DateTime? dismissedAt,
    bool holdsData = true,
  }) => backupReminderFor(
    now: now,
    lastExportAt: lastExportAt,
    dismissedAt: dismissedAt,
    holdsData: holdsData,
  );

  group('never exported', () {
    test('reminds someone who has something to lose', () {
      expect(decide(), isA<BackupNeverTaken>());
    });

    test('stays quiet on an empty app', () {
      expect(decide(holdsData: false), isA<NoBackupReminder>());
    });
  });

  group('exported before', () {
    test('stays quiet 29 days on', () {
      expect(
        decide(lastExportAt: now.subtract(const Duration(days: 29))),
        isA<NoBackupReminder>(),
      );
    });

    test('stays quiet on day 30 exactly', () {
      expect(
        decide(lastExportAt: now.subtract(const Duration(days: 30))),
        isA<NoBackupReminder>(),
      );
    });

    test('reminds 31 days on, and says how long it has been', () {
      final reminder = decide(
        lastExportAt: now.subtract(const Duration(days: 31)),
      );

      expect(reminder, isA<BackupOverdue>());
      expect((reminder as BackupOverdue).days, 31);
    });
  });

  group('dismissed', () {
    test('today, it stays quiet', () {
      expect(
        decide(dismissedAt: now.subtract(const Duration(hours: 2))),
        isA<NoBackupReminder>(),
      );
    });

    test('six days ago, it is still snoozed', () {
      expect(
        decide(dismissedAt: now.subtract(const Duration(days: 6))),
        isA<NoBackupReminder>(),
      );
    });

    test('a week ago, it reminds again', () {
      expect(
        decide(dismissedAt: now.subtract(const Duration(days: 7))),
        isA<BackupNeverTaken>(),
      );
    });
  });
}
