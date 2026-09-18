import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/database/storage_durability.dart';
import '../../../../l10n/app_localizations.dart';
import '../backup_feedback.dart';
import '../backup_providers.dart';

/// Whether the storage warning was put away for this run of the app.
///
/// Not persisted on purpose: the storage does not get any safer for having
/// been dismissed, so the next launch says it again.
final storageWarningDismissedProvider = StateProvider<bool>((ref) => false);

/// Whether the storage warning is on screen right now.
///
/// The backup reminder asks for the same export, so it stands aside while
/// this is up instead of stacking a second banner under it.
final storageWarningShownProvider = Provider<bool>(
  (ref) =>
      ref.watch(storageDurabilityProvider) != StorageDurability.durable &&
      !ref.watch(storageWarningDismissedProvider),
);

/// Says so when the browser gave the database storage that can lose it.
///
/// Non-blocking — the app is usable on IndexedDB, and plenty of people only
/// want to try it — but never silent: an app whose whole promise is "your data
/// lives on your device" must not quietly run on a device that forgets.
class StorageWarningBanner extends ConsumerWidget {
  const StorageWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durability = ref.watch(storageDurabilityProvider);
    if (!ref.watch(storageWarningShownProvider)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final volatile = durability == StorageDurability.volatile;

    return MaterialBanner(
      backgroundColor: volatile
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.tertiaryContainer,
      leading: Icon(
        volatile ? Icons.error_outline : Icons.warning_amber_outlined,
        color: volatile ? theme.colorScheme.error : null,
      ),
      content: Text(
        volatile ? l10n.storageVolatileWarning : l10n.storageDegradedWarning,
      ),
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(storageWarningDismissedProvider.notifier).state = true,
          child: Text(l10n.storageWarningDismiss),
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
          child: Text(l10n.storageExportNow),
        ),
      ],
    );
  }
}
