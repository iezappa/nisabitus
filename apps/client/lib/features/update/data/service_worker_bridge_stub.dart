/// Non-web builds have no service worker.
class ServiceWorkerBridge {
  const ServiceWorkerBridge();

  Future<bool> hasUpdate() async => false;

  Future<void> applyUpdate() async {}
}
