import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/backup_reminder.dart';
import '../backup_feedback.dart';
import '../backup_providers.dart';
import 'storage_warning_banner.dart';

/// The periodic nudge to export, docked under the open tab.
///
/// Non-blocking and easy to put off, because a reminder that gets in the way
/// gets dismissed without being read. What it never does is disappear for
/// good: "not now" snoozes it, and only an export resets the count.
class BackupReminderBanner extends ConsumerWidget {
  const BackupReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched even while hidden, so it is current the moment it can show.
    final reminder = ref.watch(backupReminderProvider).valueOrNull;
    // The storage warning already asks for an export; one banner is enough.
    if (ref.watch(storageWarningShownProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    final message = switch (reminder) {
      BackupNeverTaken() => l10n.backupReminderNever,
      BackupOverdue(:final days) => l10n.backupReminderOverdue(days),
      NoBackupReminder() || null => null,
    };
    if (message == null) return const SizedBox.shrink();

    return MaterialBanner(
      leading: const Icon(Icons.backup_outlined),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(backupHistoryProvider)
                .snoozeReminder(ref.read(clockProvider)());
            ref.invalidate(backupReminderProvider);
          },
          child: Text(l10n.backupReminderDismiss),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final outcome = await ref.read(backupActionsProvider).export();
            if (!context.mounted) return;
            showBackupOutcome(
              context,
              outcome,
              succeeded: (l10n, rows) => l10n.backupExported(rows),
            );
          },
          child: Text(l10n.backupReminderAction),
        ),
      ],
    );
  }
}
