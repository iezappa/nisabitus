import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Runs [save] and tells the user when it throws.
///
/// A write kicked off from a button has no one waiting on its future: an
/// error there goes to the zone, the dialog has already closed, and the user
/// is left believing their entry was kept. This turns that into a message
/// they can act on, and still reports the error for whoever reads the log.
Future<void> reportSaveFailure(
  BuildContext context,
  Future<void> Function() save,
) => _reportFailure(
  context,
  save,
  message: AppLocalizations.of(context).saveFailed,
  log: 'Saving a new entry failed',
);

/// Runs [delete] and tells the user when it throws.
///
/// The same silence as a failed save, the other way round: the row vanishes
/// from under the user's finger in their head, stays in the store, and turns
/// up again later with no word about why. Returns whether it went through.
Future<bool> reportDeleteFailure(
  BuildContext context,
  Future<void> Function() delete,
) => _reportFailure(
  context,
  delete,
  message: AppLocalizations.of(context).deleteFailed,
  log: 'Deleting an entry failed',
);

Future<bool> _reportFailure(
  BuildContext context,
  Future<void> Function() write, {
  required String message,
  required String log,
}) async {
  // Read before the await: the dialog that asked may be gone by the end.
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await write();
    return true;
  } on Object catch (error, stack) {
    developer.log(log, name: 'nisabitus', error: error, stackTrace: stack);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}
