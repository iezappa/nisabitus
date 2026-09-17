import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../backup/presentation/backup_feedback.dart';
import '../../backup/presentation/backup_providers.dart';
import 'update_providers.dart';

/// "A new version is available", non-blocking, under the open tab.
///
/// A release that changes the local schema recommends exporting first; one
/// the installed version is too old to reach directly says so. Dismissing
/// hides it until the next version.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(availableUpdateProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(availableUpdateProvider).valueOrNull;
    final installed = ref.watch(installedVersionProvider).valueOrNull;
    final dismissed = ref.watch(dismissedUpdateVersionProvider);
    if (info == null || dismissed == '${info.latest}') {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final unsupported = installed != null && info.isUnsupportedFrom(installed);

    return MaterialBanner(
      leading: const Icon(Icons.system_update_outlined),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.updateAvailableTitle),
          Text(l10n.updateAvailableBody('${info.latest}')),
          if (unsupported)
            Text(l10n.updateUnsupportedPath)
          else if (info.schemaChange)
            Text(l10n.updateAvailableBackupHint),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => ref
              .read(dismissedUpdateVersionProvider.notifier)
              .set('${info.latest}'),
          child: Text(l10n.updateActionDismiss),
        ),
        if (info.schemaChange || unsupported)
          TextButton(
            onPressed: () async {
              final outcome = await ref.read(backupActionsProvider).export();
              if (!context.mounted) return;
              showBackupOutcome(
                context,
                outcome,
                succeeded: (l10n, rows) => l10n.backupExported(rows),
              );
            },
            child: Text(l10n.updateActionExport),
          ),
        FilledButton.tonal(
          onPressed: () => ref.read(applyUpdateProvider)(info),
          child: Text(
            kIsWeb ? l10n.updateActionReload : l10n.updateActionDownload,
          ),
        ),
      ],
    );
  }
}
