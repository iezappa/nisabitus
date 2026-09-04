import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks before an action that cannot be undone. Returns true only on
/// confirmation.
///
/// [confirmDelete] is the common case worded for a delete; this one is for
/// everything else that throws work away — stopping a repetition, say, where
/// "Borrar" would describe the wrong thing.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context).actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// Asks before a destructive action. Returns true only on confirmation.
///
/// [body] replaces the generic "cannot be undone" line where the deletion
/// takes more with it than the thing being named — a movement, say, which
/// carries every day it was ever scheduled on.
Future<bool> confirmDelete(
  BuildContext context,
  String name, {
  String? body,
}) async {
  final l10n = AppLocalizations.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteConfirmTitle(name)),
      content: Text(body ?? l10n.deleteConfirmBody),
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
