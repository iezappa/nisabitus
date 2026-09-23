import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/auto_backup.dart';
import '../auto_backup_providers.dart';

/// The weekly copy: the switch, the folder, and what happened last time.
///
/// It says plainly that it only runs while the app is open, because the
/// alternative is someone believing a copy is being taken on a device that
/// has been shut since March. A backup nobody checks is exactly the one that
/// has to be honest about itself.
class AutoBackupCard extends ConsumerWidget {
  const AutoBackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(autoBackupActionsProvider);
    final history = ref.watch(autoBackupHistoryProvider);
    final state = ref.watch(autoBackupStateProvider).valueOrNull;
    // Watched rather than read off the state, so the switch answers the
    // moment it is pressed instead of when the folder has been looked at.
    final enabled = ref.watch(autoBackupEnabledProvider);
    final folder = history.folderLabel;

    if (!actions.isSupported) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              l10n.autoBackupUnsupported,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: enabled && folder != null,
          title: Text(l10n.autoBackupTitle),
          subtitle: Text(l10n.autoBackupHint),
          onChanged: (value) async {
            if (!value) {
              await actions.turnOff();
              return;
            }
            // Switching it on is choosing where: an enabled copy with
            // nowhere to go is a promise with nothing behind it.
            await actions.chooseFolder();
          },
        ),
        if (enabled && folder != null) ...[
          const SizedBox(height: Gap.sm),
          Text(l10n.autoBackupFolder(folder), style: theme.textTheme.bodySmall),
          const SizedBox(height: Gap.xs),
          _Status(state: state, lastRunAt: history.lastRunAt),
          const SizedBox(height: Gap.xs),
          Text(
            l10n.autoBackupWhileOpen,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.xs,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.autoBackupRunNow),
                onPressed: () async {
                  final result = await actions.runNow();
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(
                    context,
                  )?.showSnackBar(SnackBar(content: Text(_say(l10n, result))));
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.folder_outlined, size: 18),
                label: Text(l10n.autoBackupChange),
                onPressed: actions.chooseFolder,
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _say(AppLocalizations l10n, AutoBackupState state) =>
      switch (state) {
        AutoBackupWaiting() => l10n.autoBackupSaved,
        AutoBackupBroken(:final reason) => _problem(l10n, reason),
        AutoBackupOff() => l10n.autoBackupFailed,
      };

  static String _problem(AppLocalizations l10n, AutoBackupProblem problem) =>
      switch (problem) {
        AutoBackupProblem.folderGone => l10n.autoBackupFolderGone,
        AutoBackupProblem.needsPermission => l10n.autoBackupNeedsPermission,
        AutoBackupProblem.failed => l10n.autoBackupFailed,
      };
}

/// When the last copy was written, or what is stopping the next one.
class _Status extends StatelessWidget {
  const _Status({required this.state, required this.lastRunAt});

  final AutoBackupState? state;
  final DateTime? lastRunAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (state case AutoBackupBroken(:final reason)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: Gap.xs),
          Expanded(
            child: Text(
              AutoBackupCard._problem(l10n, reason),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      lastRunAt == null
          ? l10n.autoBackupNever
          : l10n.autoBackupLastRun(
              DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                  .add_Hm()
                  .format(lastRunAt!),
            ),
      style: theme.textTheme.bodySmall,
    );
  }
}
