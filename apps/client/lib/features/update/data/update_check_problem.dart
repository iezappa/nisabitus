import 'package:flutter/foundation.dart';

/// Told when an update check reached the server and could not read the answer.
///
/// Both update services answer every failure with `null`, which is right for
/// the user: being offline is normal, and a banner about a failed check is
/// noise about something they cannot act on. It is wrong for whoever ships the
/// app, because it makes "no network" and "the server is serving something
/// this app cannot parse" — a broken `version.json`, a CDN error page, a
/// release whose tag stopped matching — the same silence. The second one never
/// fixes itself, and nobody would ever hear about it.
///
/// So the user still sees nothing and the fault is still not thrown; it is
/// only written down. Offline is not a problem and is never reported.
typedef UpdateCheckProblemReporter = void Function(String what, Object cause);

/// The default: a line in the debug console, nothing in release.
///
/// `debugPrint` rather than `throw` or `assert`, because a malformed response
/// is a server's fault and must never stop the app the user is holding.
void reportUpdateCheckProblem(String what, Object cause) {
  if (kDebugMode) {
    debugPrint('Update check: $what could not be read ($cause)');
  }
}
