/// How often the app writes a copy of itself out, once it has somewhere to
/// put it.
///
/// A week, against the thirty days the reminder waits before nudging. The
/// nudge is asking a person to do something; this one costs them nothing, so
/// it can afford to be far more careful.
const autoBackupInterval = Duration(days: 7);

/// Whether a copy is owed.
///
/// [lastRunAt] null means one has never been written, and the answer is yes:
/// the point of switching this on is not waiting a week to find out whether
/// it works.
///
/// A clock that has gone backwards — a device whose date was wrong and has
/// been corrected — also answers yes. A copy written "in the future" would
/// otherwise hold the feature off until that date came round.
bool autoBackupDue({required DateTime now, required DateTime? lastRunAt}) {
  if (lastRunAt == null) return true;
  if (now.isBefore(lastRunAt)) return true;

  return now.difference(lastRunAt) >= autoBackupInterval;
}

/// What the weekly copy is called.
///
/// Dated, so a folder ends up holding a history rather than one file that
/// yesterday's copy overwrote. Sortable by name, because a folder listing is
/// how the user will look at them.
String autoBackupFileName(DateTime at) {
  final month = '${at.month}'.padLeft(2, '0');
  final day = '${at.day}'.padLeft(2, '0');

  return 'nisabit-${at.year}-$month-$day.json';
}

/// What happened on the last attempt, for the settings card to show.
sealed class AutoBackupState {
  const AutoBackupState();
}

/// Switched off, or never given a folder.
final class AutoBackupOff extends AutoBackupState {
  const AutoBackupOff();
}

/// On, with nothing owed.
final class AutoBackupWaiting extends AutoBackupState {
  const AutoBackupWaiting(this.lastRunAt);

  final DateTime? lastRunAt;
}

/// The last attempt could not be written.
///
/// Kept rather than swallowed: a copy the user believes is being taken and
/// is not is worse than no copy at all, because it is the one they will not
/// check.
final class AutoBackupBroken extends AutoBackupState {
  const AutoBackupBroken(this.reason);

  /// Why, in the user's language: the folder is gone, or permission was
  /// withdrawn, or the write itself failed.
  final AutoBackupProblem reason;
}

enum AutoBackupProblem {
  /// The folder cannot be reached: moved, deleted, or on a drive that is
  /// not plugged in.
  folderGone,

  /// The browser will not write without being asked again.
  needsPermission,

  /// Something else. The message is in the log, not on the card.
  failed,
}

/// Raised by a [BackupFolder] that knows why it could not write.
class BackupFolderException implements Exception {
  const BackupFolderException(this.problem);

  final AutoBackupProblem problem;

  @override
  String toString() => 'BackupFolderException($problem)';
}
