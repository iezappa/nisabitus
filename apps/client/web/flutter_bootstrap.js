// Custom Flutter web bootstrap (copy to apps/client/web/flutter_bootstrap.js).
//
// The two template tokens below are replaced by `flutter build web`; never
// write them inside comments (they would be substituted there too).
//
// Do NOT pass `serviceWorkerSettings` to load(): the default bootstrap does,
// and Flutter's loader then registers flutter_service_worker.js (a stub that
// unregisters itself) whenever ANY registration exists for this scope. That
// would replace sw.js and remove offline support.
// https://github.com/flutter/flutter/issues/156910

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();

// ---------- App service worker (sw.js) ----------
// Exposed to Dart as `window.appServiceWorker` (STACK-APPS-DINAMICAS.md 8.2).
(function () {
  let registration = null;
  let reloadRequested = false;

  function waitForInstalled(worker, timeoutMs) {
    if (!worker || worker.state === 'installed') return Promise.resolve();
    return new Promise((resolve) => {
      const timer = setTimeout(resolve, timeoutMs);
      worker.addEventListener('statechange', () => {
        if (worker.state === 'installed' || worker.state === 'redundant') {
          clearTimeout(timer);
          resolve();
        }
      });
    });
  }

  window.appServiceWorker = {
    /** True when a new version is installed and waiting for the user. */
    hasWaiting() {
      return !!(registration && registration.waiting && navigator.serviceWorker.controller);
    },
    /** Asks the browser to look for a new sw.js. Resolves to hasWaiting(). */
    async checkForUpdate() {
      if (!registration) return false;
      try {
        await registration.update();
        await waitForInstalled(registration.installing, 30000);
      } catch (e) {
        // Offline or server error: no update.
      }
      return this.hasWaiting();
    },
    /** User tapped "Actualizar": activate the waiting worker, then reload. */
    async applyUpdate() {
      reloadRequested = true;
      if (registration && !registration.waiting) await this.checkForUpdate();
      if (registration && registration.waiting && navigator.serviceWorker.controller) {
        registration.waiting.postMessage({ type: 'SKIP_WAITING' });
        return; // reload happens on controllerchange
      }
      window.location.reload();
    },
  };

  // Secure contexts only (HTTPS or localhost).
  if (!window.isSecureContext || !('serviceWorker' in navigator)) return;

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (reloadRequested) {
      reloadRequested = false;
      window.location.reload();
    }
  });

  // Register after the page loaded so precaching does not compete with startup.
  // Relative URL: works under GitHub Pages /<repo>/ (scope = folder of sw.js).
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('sw.js', { scope: './', updateViaCache: 'none' })
      .then((reg) => {
        registration = reg;
      })
      .catch((e) => console.warn('Service worker registration failed:', e));
  });
})();
