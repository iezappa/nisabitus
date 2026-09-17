import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('appServiceWorker')
external _AppServiceWorker? get _appServiceWorker;

extension type _AppServiceWorker._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> checkForUpdate();
  external JSPromise<JSAny?> applyUpdate();
}

/// Talks to `window.appServiceWorker`, set up by web/flutter_bootstrap.js.
class ServiceWorkerBridge {
  const ServiceWorkerBridge();

  /// True when a new version is installed and waiting for the user.
  Future<bool> hasUpdate() async {
    final worker = _appServiceWorker;
    if (worker == null) return false;
    try {
      return (await worker.checkForUpdate().toDart).toDart;
    } on Object {
      return false;
    }
  }

  /// SKIP_WAITING and reload; a plain reload without a worker.
  Future<void> applyUpdate() async {
    final worker = _appServiceWorker;
    if (worker == null) {
      web.window.location.reload();
      return;
    }
    await worker.applyUpdate().toDart;
  }
}
