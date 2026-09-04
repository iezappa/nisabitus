import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
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

      return saved
          ? BackupSucceeded(document.rowCount)
          : const BackupCancelled();
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
