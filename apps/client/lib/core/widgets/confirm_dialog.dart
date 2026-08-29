import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks before a destructive action. Returns true only on confirmation.
Future<bool> confirmDelete(BuildContext context, String name) async {
  final l10n = AppLocalizations.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteConfirmTitle(name)),
      content: Text(l10n.deleteConfirmBody),
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
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
