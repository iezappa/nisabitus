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
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = AppLocalizations.of(context).saveFailed;
  try {
    await save();
  } on Object catch (error, stack) {
    developer.log(
      'Saving a new entry failed',
      name: 'nisabitus',
      error: error,
      stackTrace: stack,
    );
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
