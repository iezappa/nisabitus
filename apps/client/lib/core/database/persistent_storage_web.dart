import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Asks the browser not to evict this origin's storage under pressure.
///
/// Best effort, and the answer is not ours to insist on: a browser may say
/// no, or not support the call at all. Neither stops a launch — the storage
/// warning and the backup reminder are what cover the rest.
Future<void> requestPersistentStorage() async {
  try {
    await web.window.navigator.storage.persist().toDart;
  } on Object {
    // Ignored on purpose; see above.
  }
}
