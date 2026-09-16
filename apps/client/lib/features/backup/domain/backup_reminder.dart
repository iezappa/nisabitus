/// Whether the app should nudge the user to export, and how.
sealed class BackupReminder {
  const BackupReminder();
}

final class NoBackupReminder extends BackupReminder {
  const NoBackupReminder();
}

/// Data exists and has never left the device.
final class BackupNeverTaken extends BackupReminder {
  const BackupNeverTaken();
}

/// The last export is older than [backupInterval].
final class BackupOverdue extends BackupReminder {
  const BackupOverdue(this.days);

  final int days;
}

/// How old the last export may get before the app says so.
const backupInterval = Duration(days: 30);

/// How long "not now" keeps the reminder away.
///
/// A week rather than a day: a reminder that returns every morning after
/// being put off stops being read, and then it protects nobody.
const backupReminderSnooze = Duration(days: 7);

/// Decides the reminder from what is known, with no clock of its own.
///
/// [holdsData] keeps a fresh install quiet: asking someone to back up an app
/// they have not written anything in yet teaches them to ignore the banner
/// before it ever matters.
BackupReminder backupReminderFor({
  required DateTime now,
  required DateTime? lastExportAt,
  required DateTime? dismissedAt,
  required bool holdsData,
}) {
  if (dismissedAt != null &&
      now.difference(dismissedAt) < backupReminderSnooze) {
    return const NoBackupReminder();
  }

  if (lastExportAt == null) {
    return holdsData ? const BackupNeverTaken() : const NoBackupReminder();
  }

  final age = now.difference(lastExportAt);
  return age > backupInterval
      ? BackupOverdue(age.inDays)
      : const NoBackupReminder();
}
