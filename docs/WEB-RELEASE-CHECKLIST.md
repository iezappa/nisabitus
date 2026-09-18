# Web release checklist (manual)

**The service worker is not tested by anything.** `web/sw.js` and
`web/flutter_bootstrap.js` are the only files in this app with no automated
coverage at all: `flutter test` runs on the Dart VM, the goldens render
widgets, and `tool/test_web.sh` drives a debug build served by `flutter drive`
— which never runs `tool/generate_sw.sh`, so the worker it would serve still
has `__APP_VERSION__` and an empty precache manifest in it. Whatever that
script proved, it would not be the thing that ships.

So this is done by hand, on the build that is actually going out, before the
tag is announced. It takes about ten minutes. Everything below has a failure
mode that costs a user their offline app or their records, which is why none
of it is optional.

Serve the release build the way a host would — `tool/serve_web.py` sets the
cross-origin isolation headers, `python3 -m http.server` does not:

```bash
cd apps/client
flutter build web --release --base-href /
sh tool/generate_sw.sh build/web pubspec.yaml
python3 tool/serve_web.py 8080          # http://localhost:8080
```

Check `build/web/sw.js` first: neither `__APP_VERSION__` nor
`__PRECACHE_MANIFEST__` may still be in it. A worker shipped with the
placeholders intact installs, caches nothing, and serves an app that is
offline-capable in name only.

## 1. Offline launch

1. Open the app, let it finish loading, use one screen.
2. DevTools → Application → Service Workers: one worker, **activated**, its
   source is `sw.js` and not `flutter_service_worker.js`. If Flutter's stub
   worker is there instead, `serviceWorkerSettings` has crept back into
   `flutter_bootstrap.js` and offline support is gone.
3. Cache Storage holds one `app-shell:` cache with the app's files in it.
4. Stop the server. Reload. **The app has to start and show the records that
   were already there.** A spinner, a blank page or a browser error page is a
   failed release.
5. Start the server again.

## 2. Update and reload

1. Bump the version, rebuild, re-run `generate_sw.sh`, keep serving.
2. In the still-open tab, trigger the check the app makes on resume (switch
   away and back, or reload once).
3. The update banner appears, and Service Workers shows a second worker
   **waiting** — it must not activate on its own.
4. Tap *Actualizar*. The page reloads once, into the new version, and the old
   cache is gone.
5. **Open the records written before the update.** They are in OPFS or
   IndexedDB, which the worker never touches — a release where they are
   missing is a release to stop.

## 3. iOS, added to the home screen

Safari's worker and storage rules are its own, and it is the platform where
this breaks quietly.

1. On an iPhone, open the served build over **HTTPS** (a service worker needs
   a secure context; `localhost` is one, a LAN IP is not).
2. Share → Add to Home Screen. Open it from the home screen, not from Safari.
3. Write one record. Close the app from the switcher, reopen it: the record is
   still there.
4. Turn on airplane mode, open it from the home screen: it launches and shows
   the record.
5. The app runs standalone — no Safari chrome — and the icon and name are the
   app's own.

## 4. Kill switch

The drill for the release that has to be withdrawn: `sw-killswitch.js` shipped
as `sw.js` unregisters the worker and drops its caches, so the next load comes
from the network.

1. Copy the kill-switch worker over the served `sw.js` and reload twice.
2. Service Workers is empty, Cache Storage has no `app-shell:` cache left.
3. The app still loads — from the network — and **its records are still
   there**. The kill switch removes the cache, never the database.
4. Restore the real `sw.js` and reload: the worker installs again.

## What this does not cover

- OPFS. `flutter drive` cannot set response headers, so CI exercises the
  IndexedDB path only; OPFS is only ever reached through a correctly
  configured host, which is step 1 above and nothing else.
- Any of this on a browser nobody opened. Chrome and Safari are checked
  because they are what users have; Firefox is not.
