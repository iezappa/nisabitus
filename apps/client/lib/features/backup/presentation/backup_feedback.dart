import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/backup_document.dart';
import 'backup_providers.dart';

/// What to tell the user about how an export or an import ended.
///
/// Null for a cancelled run: backing out of a dialog is not news. Shared by
/// every place that can start one, so an export from a banner and an export
/// from settings cannot describe the same outcome in two different ways.
String? backupOutcomeMessage(
  AppLocalizations l10n,
  BackupOutcome outcome, {
  required String Function(int rows) succeeded,
}) => switch (outcome) {
  BackupCancelled() => null,
  BackupSucceeded(:final rows, :final ignoredTables) => [
    succeeded(rows),
    // Said out loud rather than left as a smaller number: a file from
    // before a table was dropped is a real thing to open now.
    if (ignoredTables.isNotEmpty) l10n.backupSomeIgnored,
  ].join(' '),
  BackupRejected(:final problem) => switch (problem) {
    BackupProblem.notABackup => l10n.backupNotABackup,
    BackupProblem.newerVersion => l10n.backupNewerVersion,
    BackupProblem.corrupt => l10n.backupCorrupt,
  },
  // The cause goes on the end. "It could not be completed" on its own
  // leaves the user with nothing to do and nothing to report: whatever the
  // disk or the database said is the only thing that can tell them whether
  // to free space, pick another file, or write it down and ask.
  BackupFailed(:final error) => '${l10n.backupFailed}: $error',
};

/// Shows [backupOutcomeMessage] in a snack bar, replacing any older one.
void showBackupOutcome(
  BuildContext context,
  BackupOutcome outcome, {
  required String Function(AppLocalizations l10n, int rows) succeeded,
}) {
  final l10n = AppLocalizations.of(context);
  final message = backupOutcomeMessage(
    l10n,
    outcome,
    succeeded: (rows) => succeeded(l10n, rows),
  );
  if (message == null) return;

  // The previous message is about a run that already finished; leaving it
  // queued would show the user stale news before the news they asked for.
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
