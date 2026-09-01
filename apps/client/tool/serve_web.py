#!/usr/bin/env python3
"""Serves the web build the way the app needs to be served.

    python3 tool/serve_web.py [port]

Plain `python3 -m http.server` is not enough. Without the two cross-origin
isolation headers below the browser refuses to hand out `SharedArrayBuffer`,
and drift falls back from OPFS to IndexedDB, whose writes are persisted
lazily — a reload at the wrong moment leaves a database with its tables
created but not marked as created, and the app then tries to create them
again and dies on "index already exists".

Whatever ends up hosting the release build has to send the same two headers.
"""

import functools
import http.server
import os
import sys

BUILD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Cross-origin isolation: what makes SharedArrayBuffer available, and
        # with it drift's OPFS backend.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        # The build changes under the server on every rebuild; a cached
        # main.dart.js is how you end up debugging code you already replaced.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):  # quieter: one line per request is noise
        if "404" in (fmt % args):
            super().log_message(fmt, *args)


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8090
    directory = os.path.normpath(BUILD)
    if not os.path.isdir(directory):
        print(f"No web build at {directory} — run `flutter build web` first.")
        return 1

    handler = functools.partial(Handler, directory=directory)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    print(f"Serving {directory} on http://127.0.0.1:{port} (isolated origin)")
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
