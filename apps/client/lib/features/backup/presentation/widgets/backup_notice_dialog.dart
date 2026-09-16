import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/settings_providers.dart';

/// The backup notice, for someone who finished onboarding before it existed.
///
/// Shown once and only closed by accepting it: the whole point is that
/// nobody keeps using the app without having been told that no copy of their
/// data exists anywhere else.
Future<void> showBackupNoticeDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => const _BackupNoticeDialog(),
);

class _BackupNoticeDialog extends ConsumerWidget {
  const _BackupNoticeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.phone_android_outlined),
        title: Text(l10n.backupNoticeTitle),
        content: SizedBox(width: 420, child: Text(l10n.backupNoticeOnboarding)),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(backupNoticeAcceptedProvider.notifier).set(true);
              Navigator.of(context).pop();
            },
            child: Text(l10n.backupNoticeAccept),
          ),
        ],
      ),
    );
  }
}
