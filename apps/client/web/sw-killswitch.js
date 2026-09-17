// Kill switch for a broken sw.js. NOT copied into builds by default.
//
// How to use (emergency release):
//   1. Replace the CONTENT of web/sw.js with this file (same URL: the browser
//      only checks the registered script URL, ./sw.js).
//   2. Tag a release. tool/generate_sw.sh finds no placeholders and leaves the
//      file as is.
//   3. On the next visit the browser sees new bytes, installs this worker,
//      which activates immediately, deletes this app's caches, unregisters
//      itself and reloads open windows from the network.
//   4. Once users recovered (a few days), restore the fixed sw.js in a new release.
//
// It never touches OPFS, IndexedDB or localStorage: user data is safe.

'use strict';

const CACHE_PREFIX = `app-shell:${self.registration.scope}:`;

self.addEventListener('install', () => {
  self.skipWaiting(); // intentional here: recovery must not wait
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names.filter((name) => name.startsWith(CACHE_PREFIX)).map((name) => caches.delete(name)),
      );
      await self.registration.unregister();
      const windows = await self.clients.matchAll({ type: 'window' });
      windows.forEach((client) => client.navigate(client.url));
    })(),
  );
});
