import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/auto_backup.dart';
import '../auto_backup_providers.dart';

/// Says so when the weekly copy could not be written.
///
/// Docked with the other data-safety notices rather than left on the
/// settings card, because nobody opens settings weekly — and a copy the user
/// believes is being taken and is not is worse than no copy at all. It is
/// the one they will not check.
///
/// It carries the way out too: in a browser the usual reason is permission
/// that has to be asked for again, and asking needs a press.
class AutoBackupBanner extends ConsumerWidget {
  const AutoBackupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(autoBackupStateProvider).valueOrNull;
    if (state is! AutoBackupBroken) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return MaterialBanner(
      leading: const Icon(Icons.save_outlined),
      content: Text(switch (state.reason) {
        AutoBackupProblem.folderGone => l10n.autoBackupFolderGone,
        AutoBackupProblem.needsPermission => l10n.autoBackupNeedsPermission,
        AutoBackupProblem.failed => l10n.autoBackupFailed,
      }),
      actions: [
        FilledButton.tonal(
          onPressed: () async {
            final actions = ref.read(autoBackupActionsProvider);
            // A folder that is gone cannot be written to: that one needs a
            // new folder, not another attempt.
            final result = state.reason == AutoBackupProblem.folderGone
                ? (await actions.chooseFolder()
                      ? const AutoBackupWaiting(null)
                      : state)
                : await actions.runNow();
            if (!context.mounted || result is AutoBackupBroken) return;

            ScaffoldMessenger.maybeOf(context)
                ?.showSnackBar(SnackBar(content: Text(l10n.autoBackupSaved)));
          },
          child: Text(
            state.reason == AutoBackupProblem.folderGone
                ? l10n.autoBackupChoose
                : l10n.autoBackupRunNow,
          ),
        ),
      ],
    );
  }
}
