import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'confirm_dialog.dart';

/// A dialog title with the bin in the corner.
///
/// Every editing modal in the app carries the same one, so deleting is never
/// somewhere different depending on what is being edited. It appears only
/// when there is something to delete — a form for a thing that does not
/// exist yet has nothing to offer.
class DialogTitle extends StatelessWidget {
  const DialogTitle({
    required this.text,
    this.onDelete,
    this.deleteLabel,
    this.deleteBody,
    super.key,
  });

  final String text;
  final Future<void> Function()? onDelete;

  /// Named in the confirmation, so the user sees what they are about to lose.
  final String? deleteLabel;

  /// What the confirmation says beyond the name, for a deletion that takes
  /// more with it than the thing being named. Defaults to the generic line.
  final String? deleteBody;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(child: Text(text)),
        if (onDelete case final delete?)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.actionDelete,
            color: Theme.of(context).colorScheme.error,
            onPressed: () async {
              if (await confirmDelete(
                context,
                deleteLabel ?? text,
                body: deleteBody,
              )) {
                await delete();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
      ],
    );
  }
}
