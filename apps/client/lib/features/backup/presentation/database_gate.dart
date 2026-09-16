import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_health.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/centered_content.dart';
import '../../../l10n/app_localizations.dart';
import 'backup_feedback.dart';
import 'backup_providers.dart';

/// Stands between the app and a database that would not open.
///
/// Without it, a store that fails to open fails every screen at once — each
/// one reads from it — and leaves nothing on screen to act on. With it, the
/// user gets the two ways out that do not involve guessing.
///
/// While the check runs the app is shown as usual: the screens are waiting
/// on the same open, and a spinner over them would only delay a healthy
/// launch.
class DatabaseGate extends ConsumerWidget {
  const DatabaseGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(databaseHealthProvider).valueOrNull;
    if (health is! DatabaseUnopenable) return child;

    // Its own navigator: this sits above the app's, and the confirmation
    // dialogs need one to open on.
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const DatabaseRecoveryScreen(),
      ),
    );
  }
}

class DatabaseRecoveryScreen extends ConsumerStatefulWidget {
  const DatabaseRecoveryScreen({super.key});

  @override
  ConsumerState<DatabaseRecoveryScreen> createState() =>
      _DatabaseRecoveryScreenState();
}

class _DatabaseRecoveryScreenState
    extends ConsumerState<DatabaseRecoveryScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
      title: l10n.recoveryImportConfirmTitle,
      body: l10n.recoveryImportConfirmBody,
      action: l10n.backupImport,
    )) {
      return;
    }

    await _run(() async {
      final outcome = await ref
          .read(databaseRecoveryActionsProvider)
          .importBackup();
      if (!mounted) return;
      showBackupOutcome(
        context,
        outcome,
        succeeded: (l10n, rows) => l10n.backupImported(rows),
      );
    });
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
      title: l10n.recoveryResetConfirmTitle,
      body: l10n.recoveryResetConfirmBody,
      action: l10n.recoveryResetConfirmAction,
    )) {
      return;
    }

    await _run(ref.read(databaseRecoveryActionsProvider).reset);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CenteredContent(
          child: ListView(
            padding: const EdgeInsets.all(Gap.xl),
            children: [
              Icon(
                Icons.report_problem_outlined,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: Gap.lg),
              Text(
                l10n.recoveryTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.md),
              Text(
                l10n.recoveryBody,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.xl),
              FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.recoveryImport),
              ),
              const SizedBox(height: Gap.md),
              OutlinedButton.icon(
                onPressed: _busy ? null : _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.recoveryReset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
