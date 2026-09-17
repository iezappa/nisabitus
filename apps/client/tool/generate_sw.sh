#!/bin/sh
# Injects the app version and the precache manifest into build/web/sw.js.
# Copy to apps/client/tool/generate_sw.sh. Run AFTER `flutter build web`
# (and after any file is added to build/web, e.g. 404.html):
#
#   sh tool/generate_sw.sh [build_dir] [pubspec]
#
# POSIX sh + coreutils (sha256sum) + awk. No Node, no Dart packages.
set -eu

BUILD_DIR="${1:-build/web}"
PUBSPEC="${2:-pubspec.yaml}"
SW="$BUILD_DIR/sw.js"

[ -f "$SW" ] || { echo "error: $SW not found (is web/sw.js committed?)" >&2; exit 1; }

# Kill-switch release: nothing to inject.
if ! grep -qF '/*__PRECACHE_MANIFEST__*/' "$SW"; then
  echo "sw.js has no placeholders (kill switch?): left unchanged"
  exit 0
fi

VERSION="$(sed -n 's/^version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$PUBSPEC")"
[ -n "$VERSION" ] || { echo "error: no version in $PUBSPEC" >&2; exit 1; }

# Excluded: the worker itself, network-only files, Flutter's stub worker,
# the Pages SPA fallback, source maps, debug symbols and dotfiles.
MANIFEST="$(
  cd "$BUILD_DIR"
  find . -type f \
    ! -name 'sw.js' ! -name 'sw-killswitch.js' \
    ! -name 'flutter_service_worker.js' \
    ! -name 'version.json' ! -name 'update.json' ! -name '404.html' \
    ! -name '*.map' ! -name '*.symbols' ! -name '.*' \
    | LC_ALL=C sort \
    | while IFS= read -r file; do
        path="${file#./}"
        case "$path" in *'"'*|*'\'*) echo "error: unsupported file name: $path" >&2; exit 1;; esac
        rev="$(sha256sum "$file" | cut -d' ' -f1)"
        printf '{"url":"%s","rev":"%s"},' "$path" "$rev"
      done
)"
MANIFEST="[${MANIFEST%,}]"

TMP="$SW.tmp"
awk -v version="$VERSION" -v manifest="$MANIFEST" '
  /^const APP_VERSION = / { sub(/__APP_VERSION__/, version) }
  /\/\*__PRECACHE_MANIFEST__\*\/ \[\]/ { sub(/\/\*__PRECACHE_MANIFEST__\*\/ \[\]/, manifest) }
  { print }
' "$SW" > "$TMP"
mv "$TMP" "$SW"

if grep -qF -e "'__APP_VERSION__'" -e '/*__PRECACHE_MANIFEST__*/' "$SW"; then
  echo "error: placeholders left in $SW" >&2
  exit 1
fi

COUNT="$(printf '%s' "$MANIFEST" | grep -o '"url"' | wc -l | tr -d ' ')"
echo "sw.js: version $VERSION, $COUNT precached files"
