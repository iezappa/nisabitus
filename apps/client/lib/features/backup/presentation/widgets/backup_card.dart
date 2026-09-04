import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/backup_document.dart';
import '../backup_providers.dart';

/// Export and import, in the one place the user goes looking for them.
///
/// The warning sits above the buttons rather than only inside the
/// confirmation: someone should know what Import does before they press it,
/// not only after.
class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  /// Both buttons go quiet while either is working: a second export mid
  /// import would be reading a store that is being rewritten.
  bool _busy = false;

  /// [succeeded] names what happened, since the two flows share everything
  /// else about how an outcome is reported.
  Future<void> _run(
    Future<BackupOutcome> Function() action,
    String Function(AppLocalizations l10n, int rows) succeeded,
  ) async {
    setState(() => _busy = true);
    try {
      _report(await action(), succeeded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(
    ref.read(backupActionsProvider).export,
    (l10n, rows) => l10n.backupExported(rows),
  );

  Future<void> _import() async {
    if (!await _confirmReplace()) return;

    await _run(
      ref.read(backupActionsProvider).import,
      (l10n, rows) => l10n.backupImported(rows),
    );
  }

  Future<bool> _confirmReplace() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupConfirmTitle),
        content: Text(l10n.backupConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.backupConfirmAction),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _report(
    BackupOutcome outcome,
    String Function(AppLocalizations l10n, int rows) succeeded,
  ) {
    if (!mounted || outcome is BackupCancelled) return;

    final l10n = AppLocalizations.of(context);
    final message = switch (outcome) {
      BackupSucceeded(:final rows, :final ignoredTables) => [
        succeeded(l10n, rows),
        // Said out loud rather than left as a smaller number: a file from
        // before a table was dropped is a real thing to open now.
        if (ignoredTables.isNotEmpty) l10n.backupSomeIgnored,
      ].join(' '),
      BackupRejected(:final problem) => switch (problem) {
        BackupProblem.notABackup => l10n.backupNotABackup,
        BackupProblem.newerVersion => l10n.backupNewerVersion,
        BackupProblem.corrupt => l10n.backupCorrupt,
      },
      BackupFailed() => l10n.backupFailed,
      BackupCancelled() => '',
    };

    // The previous message is about a run that already finished; leaving it
    // queued would show the user stale news before the news they asked for.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // No card around it: settings is a flat column, and only the support
    // block — a paragraph with two buttons — keeps its box.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.backupHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: Gap.sm),
        Text(
          l10n.backupReplaceWarning,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.backupExport),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.backupImport),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
