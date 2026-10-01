import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences.dart';
import '../../../core/database/app_database.dart';
import '../../backup/domain/backup_document.dart';
import '../../backup/domain/restore_report.dart';
import '../../backup/presentation/backup_providers.dart';
import '../../exercise/presentation/exercise_providers.dart';
import '../../habits/presentation/habit_providers.dart';
import '../../journal/presentation/journal_providers.dart';
import '../../medication/presentation/medication_providers.dart';
import '../../nutrition/presentation/nutrition_providers.dart';
import '../../pomodoro/presentation/pomodoro_providers.dart';
import '../../sleep/presentation/sleep_providers.dart';
import '../../streaks/presentation/streak_providers.dart';
import '../../todo/presentation/todo_providers.dart';
import '../data/nisabitus_server_client.dart';
import '../domain/server_account.dart';

final serverBaseUrlProvider = StateNotifierProvider<StringPreference, String>(
  (ref) => StringPreference(
    ref.watch(sharedPreferencesProvider),
    'serverAccount.baseUrl',
    fallback: '',
  ),
);

final serverUsernameProvider = StateNotifierProvider<StringPreference, String>(
  (ref) => StringPreference(
    ref.watch(sharedPreferencesProvider),
    'serverAccount.username',
    fallback: '',
  ),
);

final serverTokenProvider = StateNotifierProvider<StringPreference, String>(
  (ref) => StringPreference(
    ref.watch(sharedPreferencesProvider),
    'serverAccount.token',
    fallback: '',
  ),
);

final serverAccountProvider = Provider<ServerAccount>(
  (ref) => ServerAccount(
    baseUrl: ref.watch(serverBaseUrlProvider),
    username: ref.watch(serverUsernameProvider),
    token: ref.watch(serverTokenProvider),
  ),
);

final serverAccountActionsProvider = Provider<ServerAccountActions>(
  ServerAccountActions.new,
);

class ServerAccountActions {
  ServerAccountActions(this._ref);

  final Ref _ref;

  Future<void> connect({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final client = NisabitusServerClient(baseUrl: baseUrl);
    await client.healthCheck();
    final login = await client.login(username: username, password: password);
    _ref.read(serverBaseUrlProvider.notifier).set(baseUrl.trim());
    _ref.read(serverUsernameProvider.notifier).set(login.username.trim());
    _ref.read(serverTokenProvider.notifier).set(login.token);
  }

  Future<void> disconnect() async {
    final account = _ref.read(serverAccountProvider);
    if (account.isConnected) {
      try {
        await NisabitusServerClient(baseUrl: account.baseUrl)
            .logout(account.token);
      } on Object {
        // Disconnect is local authority. A missing network must not keep a token
        // in this device after the user asked to remove it.
      }
    }
    _ref.read(serverTokenProvider.notifier).set('');
    _ref.read(serverUsernameProvider.notifier).set('');
  }

  Future<BackupOutcome> uploadLocalBackup() async {
    final account = _ref.read(serverAccountProvider);
    if (!account.isConnected) {
      return const BackupFailed(ServerAccountException('Not connected'));
    }

    try {
      final document = await _ref.read(backupRepositoryProvider).export();
      final result = await NisabitusServerClient(baseUrl: account.baseUrl)
          .uploadBackup(token: account.token, document: document);
      return BackupSucceeded(result.rowCount);
    } on Object catch (error) {
      return BackupFailed(error);
    }
  }

  Future<BackupOutcome> downloadServerBackup() async {
    final account = _ref.read(serverAccountProvider);
    if (!account.isConnected) {
      return const BackupFailed(ServerAccountException('Not connected'));
    }

    try {
      final BackupDocument document =
          await NisabitusServerClient(baseUrl: account.baseUrl).downloadBackup(
            token: account.token,
            supportedSchemaVersion: AppDatabase.currentSchemaVersion,
          );
      final RestoreReport report = await _ref
          .read(backupRepositoryProvider)
          .restore(document);
      _refreshEveryModule();
      return BackupSucceeded(report.rows, ignoredTables: report.ignoredTables);
    } on Object catch (error) {
      return BackupFailed(error);
    }
  }

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
}
