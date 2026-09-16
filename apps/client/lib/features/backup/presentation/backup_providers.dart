import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app/app_restart.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/local_store.dart';
import '../../../core/preferences/preferences.dart';
import '../../../core/time/clock.dart';
import '../../exercise/presentation/exercise_providers.dart';
import '../../habits/presentation/habit_providers.dart';
import '../../journal/presentation/journal_providers.dart';
import '../../medication/presentation/medication_providers.dart';
import '../../nutrition/presentation/nutrition_providers.dart';
import '../../pomodoro/presentation/pomodoro_providers.dart';
import '../../sleep/presentation/sleep_providers.dart';
import '../../streaks/presentation/streak_providers.dart';
import '../../todo/presentation/todo_providers.dart';
import '../data/drift_backup_repository.dart';
import '../data/picker_backup_files.dart';
import '../domain/backup_document.dart';
import '../domain/backup_files.dart';
import '../domain/backup_reminder.dart';
import '../domain/backup_repository.dart';
import '../domain/restore_report.dart';

/// How an export or an import ended.
sealed class BackupOutcome {
  const BackupOutcome();
}

/// The user closed the dialog. Nothing happened, and nothing went wrong.
final class BackupCancelled extends BackupOutcome {
  const BackupCancelled();
}

final class BackupSucceeded extends BackupOutcome {
  const BackupSucceeded(this.rows, {this.ignoredTables = const {}});

  /// Rows written on the way in, or written to the file on the way out.
  final int rows;

  /// Tables an imported file carried that this version has no home for.
  ///
  /// Empty on export, and on any import of a file this version wrote. When
  /// it is not, the count above is smaller than the file — and the user is
  /// told that rather than left to notice.
  final Set<String> ignoredTables;
}

/// The file was read and turned down, with a reason worth showing.
final class BackupRejected extends BackupOutcome {
  const BackupRejected(this.problem);

  final BackupProblem problem;
}

/// Everything else: the disk, the database, a file that parsed but would not
/// go back in.
final class BackupFailed extends BackupOutcome {
  const BackupFailed(this.error);

  final Object error;
}

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => DriftBackupRepository(ref.watch(databaseProvider)),
);

/// Overridden in tests, where there is no native dialog to open.
final backupFilesProvider = Provider<BackupFiles>(
  (ref) => const PickerBackupFiles(),
);

/// Export and import, kept out of the widgets.
class BackupActions {
  BackupActions(this._ref);

  final Ref _ref;

  Future<BackupOutcome> export() async {
    try {
      final document = await _ref.read(backupRepositoryProvider).export();
      final saved = await _ref
          .read(backupFilesProvider)
          .save(_fileNameFor(document.exportedAt), document.encode());

      if (!saved) return const BackupCancelled();

      await _ref
          .read(backupHistoryProvider)
          .recordExport(_ref.read(clockProvider)());
      _ref.invalidate(backupReminderProvider);

      return BackupSucceeded(document.rowCount);
    } on Object catch (error) {
      return BackupFailed(error);
    }
  }

  Future<BackupOutcome> import() async {
    final source = await _ref.read(backupFilesProvider).open();
    if (source == null) return const BackupCancelled();

    final BackupDocument document;
    try {
      document = BackupDocument.parse(
        source,
        supportedSchemaVersion: _ref.read(databaseProvider).schemaVersion,
      );
    } on BackupFormatException catch (error) {
      return BackupRejected(error.reason);
    }

    final RestoreReport report;
    try {
      report = await _ref.read(backupRepositoryProvider).restore(document);
    } on Object catch (error) {
      return BackupFailed(error);
    }

    _refreshEveryModule();

    // The report, not the document: the file can describe rows this version
    // has nowhere to put, and claiming those came back would make restore —
    // the only recovery path there is — lie about what it recovered.
    return BackupSucceeded(report.rows, ignoredTables: report.ignoredTables);
  }

  /// Every module caches behind a revision counter, so a restore that does
  /// not bump them leaves the screens showing a store that no longer exists.
  void _refreshEveryModule() {
    for (final revision in [
      habitsRevisionProvider,
      streaksRevisionProvider,
      sleepRevisionProvider,
      journalRevisionProvider,
      pomodoroRevisionProvider,
      todoRevisionProvider,
      nutritionRevisionProvider,
      exerciseRevisionProvider,
      medicationRevisionProvider,
    ]) {
      _ref.read(revision.notifier).update((value) => value + 1);
    }
  }

  /// Dated rather than timestamped: a person looking at a folder wants to
  /// know which day a backup is from, not which second.
  static String _fileNameFor(DateTime moment) {
    final month = '${moment.month}'.padLeft(2, '0');
    final day = '${moment.day}'.padLeft(2, '0');

    return 'nisabit-${moment.year}-$month-$day.json';
  }
}

final backupActionsProvider = Provider<BackupActions>(BackupActions.new);

/// The way out of a store that cannot be opened.
///
/// Neither option tries to repair the store in place: a database that fails
/// to open has already shown it cannot be trusted, and a repair that guesses
/// wrong looks exactly like one that worked. Both start from empty, both are
/// asked for explicitly, and both end by starting the app again.
class DatabaseRecoveryActions {
  DatabaseRecoveryActions(this._ref);

  final Ref _ref;

  /// Deletes the store and starts the app over, empty.
  Future<void> reset() async {
    await _eraseStore();
    _ref.read(restartAppProvider)();
  }

  /// Puts a backup file where the broken store was.
  ///
  /// The file is read and checked before anything is deleted, so picking the
  /// wrong one — or backing out — leaves the device exactly as it was.
  Future<BackupOutcome> importBackup() async {
    final source = await _ref.read(backupFilesProvider).open();
    if (source == null) return const BackupCancelled();

    final BackupDocument document;
    try {
      document = BackupDocument.parse(
        source,
        supportedSchemaVersion: AppDatabase.currentSchemaVersion,
      );
    } on BackupFormatException catch (error) {
      return BackupRejected(error.reason);
    }

    try {
      await _eraseStore();
      // A connection that failed to open stays failed, so the restore needs
      // a new one on the new, empty store.
      _ref.invalidate(databaseProvider);
      final report = await _ref
          .read(backupRepositoryProvider)
          .restore(document);
      _ref.read(restartAppProvider)();

      return BackupSucceeded(report.rows, ignoredTables: report.ignoredTables);
    } on Object catch (error) {
      return BackupFailed(error);
    }
  }

  Future<void> _eraseStore() async {
    try {
      await _ref.read(databaseProvider).close();
    } on Object {
      // Closing a connection that never opened can fail too. The storage is
      // about to be deleted either way.
    }
    await _ref.read(eraseLocalStoreProvider)();
  }
}

final databaseRecoveryActionsProvider = Provider<DatabaseRecoveryActions>(
  DatabaseRecoveryActions.new,
);

/// When the user last exported, and last put the reminder off.
///
/// Stored as ISO-8601 text in preferences rather than in the database: the
/// database is what the backup carries, and a restore must not bring back
/// the date of an export that happened on another device.
class BackupHistory {
  BackupHistory(this._prefs);

  final SharedPreferences _prefs;

  static const lastExportKey = 'backup.lastExportAt';
  static const reminderDismissedKey = 'backup.reminderDismissedAt';

  DateTime? get lastExportAt => _read(lastExportKey);

  DateTime? get reminderDismissedAt => _read(reminderDismissedKey);

  Future<void> recordExport(DateTime at) =>
      _prefs.setString(lastExportKey, at.toIso8601String());

  Future<void> snoozeReminder(DateTime at) =>
      _prefs.setString(reminderDismissedKey, at.toIso8601String());

  DateTime? _read(String key) {
    final stored = _prefs.getString(key);
    return stored == null ? null : DateTime.tryParse(stored);
  }
}

final backupHistoryProvider = Provider<BackupHistory>(
  (ref) => BackupHistory(ref.watch(sharedPreferencesProvider)),
);

/// Whether to nudge the user to export, decided once per launch.
final backupReminderProvider = FutureProvider<BackupReminder>((ref) async {
  final history = ref.watch(backupHistoryProvider);

  return backupReminderFor(
    now: ref.watch(clockProvider)(),
    lastExportAt: history.lastExportAt,
    dismissedAt: history.reminderDismissedAt,
    holdsData: await ref.watch(backupRepositoryProvider).holdsUserData(),
  );
});

/// "Delete all my data": the store, the preferences, and back to the start.
class EraseAllDataActions {
  EraseAllDataActions(this._ref);

  final Ref _ref;

  /// Preferences that survive erasing everything.
  ///
  /// How the app looks and which language it speaks. None of it says
  /// anything about the person, and losing it would greet them — right after
  /// they deleted everything — in a language they may not read.
  static const kept = {
    'settings.language',
    'settings.theme',
    'settings.accent',
  };

  Future<void> eraseEverything() async {
    await _ref.read(backupRepositoryProvider).eraseEverything();

    final prefs = _ref.read(sharedPreferencesProvider);
    for (final key in prefs.getKeys().difference(kept)) {
      await prefs.remove(key);
    }

    // Onboarding is gone with the rest, so the restart lands on it.
    _ref.read(restartAppProvider)();
  }
}

final eraseAllDataActionsProvider = Provider<EraseAllDataActions>(
  EraseAllDataActions.new,
);
