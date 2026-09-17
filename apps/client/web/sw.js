// App-shell service worker for local-first Flutter web apps (Profile A).
//
// Copy to apps/client/web/sw.js. `flutter build web` copies it to build/web/,
// then tool/generate_sw.sh replaces the two placeholders below:
//   __APP_VERSION__         version from pubspec.yaml (x.y.z+build)
//   __PRECACHE_MANIFEST__   [{"url": "main.dart.js", "rev": "<sha256>"}, ...]
// Any changed file changes this script's bytes, so the browser installs a new
// worker and a new cache on the next update check.
//
// Rules (see STACK-APPS-DINAMICAS.md 8.2):
//   - No automatic skipWaiting(): a new version waits until the app posts
//     {type: 'SKIP_WAITING'} (user tapped "Actualizar"). The page reloads on
//     `controllerchange` (see flutter_bootstrap.js).
//   - version.json and update.json are network-only (never cached).
//   - Cache Storage is separate from OPFS/IndexedDB: this worker never touches
//     user data.
//   - Cached responses keep the headers of the original network response
//     (COOP/COEP/CORP from nginx), so cross-origin isolation survives offline.

'use strict';

const APP_VERSION = '__APP_VERSION__';
const PRECACHE_MANIFEST = /*__PRECACHE_MANIFEST__*/ [];

// Scope in the prefix: several apps can share one origin
// (e.g. <owner>.github.io/<repo-a>/ and /<repo-b>/) and one Cache Storage.
const SCOPE = self.registration.scope;
const CACHE_PREFIX = `app-shell:${SCOPE}:`;
const NETWORK_ONLY = ['version.json', 'update.json'];

function manifestHash() {
  // Small non-cryptographic hash (FNV-1a) of the revisions, only to name the cache.
  let h = 0x811c9dc5;
  for (const { url, rev } of PRECACHE_MANIFEST) {
    for (const ch of url + rev) {
      h ^= ch.charCodeAt(0);
      h = Math.imul(h, 0x01000193);
    }
  }
  return (h >>> 0).toString(16);
}

const CACHE_NAME = `${CACHE_PREFIX}${APP_VERSION}-${manifestHash()}`;
const INDEX_URL = new URL('index.html', SCOPE).href;

// Safari refuses redirected responses for navigations: store a clean copy.
async function cleanResponse(response) {
  if (!response.redirected) return response;
  const body = await response.blob();
  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      // Fetch through the real server (cache: 'reload' skips the HTTP cache)
      // so the stored responses carry the server headers. If one file fails,
      // install fails and the previous worker keeps serving: never half a shell.
      await Promise.all(
        PRECACHE_MANIFEST.map(async ({ url }) => {
          const absolute = new URL(url, SCOPE).href;
          const response = await fetch(absolute, { cache: 'reload' });
          if (!response.ok) throw new Error(`Precache failed: ${url} (${response.status})`);
          await cache.put(absolute, await cleanResponse(response));
        }),
      );
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
          .map((name) => caches.delete(name)),
      );
    })(),
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || request.headers.has('range')) return;

  const url = new URL(request.url);
  // Cross-origin or outside this app's scope: let the browser handle it.
  if (url.origin !== self.location.origin || !request.url.startsWith(SCOPE)) return;

  const relativePath = request.url.slice(SCOPE.length).split(/[?#]/)[0];
  if (NETWORK_ONLY.includes(relativePath)) return; // network-only

  if (request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(request));
    return;
  }
  event.respondWith(cacheFirst(request));
});

async function networkFirstNavigation(request) {
  try {
    return await fetch(request);
  } catch (error) {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(INDEX_URL);
    if (cached) return cached;
    throw error;
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request, { ignoreSearch: true });
  return cached || fetch(request);
}
