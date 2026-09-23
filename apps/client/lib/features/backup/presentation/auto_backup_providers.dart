import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/preferences/preferences.dart';
import '../../../core/time/clock.dart';
import '../data/backup_folder_platform.dart';
import '../domain/auto_backup.dart';
import '../domain/backup_folder.dart';
import 'backup_providers.dart';

/// Overridden in tests, where there is no folder to write into.
final backupFolderProvider = Provider<BackupFolder>(
  (ref) => backupFolderFor(ref.watch(sharedPreferencesProvider)),
);

/// Whether the weekly copy is switched on.
final autoBackupEnabledProvider = StateNotifierProvider<BoolPreference, bool>((
  ref,
) {
  return BoolPreference(
    ref.watch(sharedPreferencesProvider),
    'backup.autoEnabled',
    fallback: false,
  );
});

/// When the last automatic copy was written.
///
/// Its own record rather than the export one: a copy the app wrote is not
/// the user taking their data somewhere, and the reminder should keep
/// nudging for that. It is stored in preferences for the reason the rest of
/// the backup history is — a restore must not bring back another device's
/// dates.
class AutoBackupHistory {
  AutoBackupHistory(this._prefs);

  final SharedPreferences _prefs;

  static const lastRunKey = 'backup.autoLastRunAt';
  static const folderKey = 'backup.autoFolderLabel';

  DateTime? get lastRunAt {
    final stored = _prefs.getString(lastRunKey);
    return stored == null ? null : DateTime.tryParse(stored);
  }

  /// What to call the folder on screen. Null when none was chosen.
  String? get folderLabel => _prefs.getString(folderKey);

  Future<void> recordRun(DateTime at) =>
      _prefs.setString(lastRunKey, at.toIso8601String());

  Future<void> rememberFolder(String label) =>
      _prefs.setString(folderKey, label);

  Future<void> forgetFolder() async {
    await _prefs.remove(folderKey);
    await _prefs.remove(lastRunKey);
  }
}

final autoBackupHistoryProvider = Provider<AutoBackupHistory>(
  (ref) => AutoBackupHistory(ref.watch(sharedPreferencesProvider)),
);

/// Bumped after every attempt, so the card refetches.
final autoBackupRevisionProvider = StateProvider<int>((ref) => 0);

/// What the settings card shows: off, waiting, or broken and why.
final autoBackupStateProvider = FutureProvider<AutoBackupState>((ref) async {
  ref.watch(autoBackupRevisionProvider);

  final history = ref.watch(autoBackupHistoryProvider);
  if (!ref.watch(autoBackupEnabledProvider) || history.folderLabel == null) {
    return const AutoBackupOff();
  }

  try {
    // Asked of the folder itself, not of the label we stored: a folder can
    // be deleted, unplugged or un-permitted between one launch and the
    // next, and the only honest way to know is to look.
    await ref.watch(backupFolderProvider).remembered();
    return AutoBackupWaiting(history.lastRunAt);
  } on BackupFolderException catch (error) {
    return AutoBackupBroken(error.problem);
  } on Object {
    return const AutoBackupBroken(AutoBackupProblem.failed);
  }
});

/// Switching it on and off, and the copy itself.
class AutoBackupActions {
  AutoBackupActions(this._ref);

  final Ref _ref;

  BackupFolder get _folder => _ref.read(backupFolderProvider);
  AutoBackupHistory get _history => _ref.read(autoBackupHistoryProvider);

  /// Whether this build can keep a folder at all.
  bool get isSupported => _folder.isSupported;

  /// Asks for a folder and switches the weekly copy on.
  ///
  /// Returns false when the user backed out of the picker, which is not a
  /// failure and leaves everything as it was.
  Future<bool> chooseFolder() async {
    final label = await _folder.choose();
    if (label == null) return false;

    await _history.rememberFolder(label);
    _ref.read(autoBackupEnabledProvider.notifier).set(true);
    _bump();

    // Written straight away rather than a week from now: the point of
    // switching this on is knowing that it works, and a folder that turns
    // out to be unwritable should say so while the user is still looking.
    await runNow();
    return true;
  }

  Future<void> turnOff() async {
    _ref.read(autoBackupEnabledProvider.notifier).set(false);
    await _folder.forget();
    await _history.forgetFolder();
    _bump();
  }

  /// Writes a copy now, whatever the calendar says.
  ///
  /// Returns what happened, so the card can say it. Never throws: a failed
  /// backup must not take a screen down with it.
  Future<AutoBackupState> runNow() async {
    if (!_ref.read(autoBackupEnabledProvider)) return const AutoBackupOff();

    try {
      final document = await _ref.read(backupRepositoryProvider).export();
      final at = _ref.read(clockProvider)();
      await _folder.write(autoBackupFileName(at), document.encode());
      await _history.recordRun(at);
      _bump();

      return AutoBackupWaiting(at);
    } on BackupFolderException catch (error) {
      _bump();
      return AutoBackupBroken(error.problem);
    } on Object catch (error, stack) {
      developer.log(
        'The weekly copy could not be written',
        name: 'nisabitus',
        error: error,
        stackTrace: stack,
      );
      _bump();
      return const AutoBackupBroken(AutoBackupProblem.failed);
    }
  }

  /// Writes one if a week has gone by, and nothing otherwise.
  ///
  /// This is the whole of "automatic": there is no process behind the app to
  /// wake it up, on any of the platforms it runs on, so the copy is taken
  /// the next time the app is opened after a week has passed. A browser
  /// cannot even do that unasked — it wants a click before it will write to
  /// a folder — which is why a failure here surfaces on the card instead of
  /// being retried in silence.
  Future<void> runIfDue() async {
    if (!_ref.read(autoBackupEnabledProvider)) return;
    if (_history.folderLabel == null) return;

    if (!autoBackupDue(
      now: _ref.read(clockProvider)(),
      lastRunAt: _history.lastRunAt,
    )) {
      return;
    }

    await runNow();
  }

  void _bump() =>
      _ref.read(autoBackupRevisionProvider.notifier).update((v) => v + 1);
}

final autoBackupActionsProvider = Provider<AutoBackupActions>(
  AutoBackupActions.new,
);
