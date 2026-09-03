#!/usr/bin/env bash
# Drives the app end to end in a real browser.
#
#     tool/test_web.sh
#
# The unit tests run on the Dart VM and the goldens render widgets, so neither
# of them has ever loaded the web build. That is not a theoretical gap: the
# database shipped for months with no web backend at all, every screen failed
# at its first query, and the whole suite stayed green. It was found by opening
# the app by hand. This is that hand, automated.
#
# On the web the test and the app do not share a process — the app runs in the
# browser and the test drives it over WebDriver — so this needs chromedriver
# running and `test_driver/integration_test.dart` on the other side of the wire.
#
# Two things this does NOT cover, both on purpose:
#
#   * `flutter drive` has no way to set response headers, so the page is served
#     without cross-origin isolation and drift falls back from OPFS to
#     IndexedDB. That is the same storage GitHub Pages gives, so it is worth
#     exercising — but the OPFS path stays untested. `tool/serve_web.py` is
#     what a correctly configured host looks like.
#   * It runs headless. A visible browser is `--no-headless`.
set -euo pipefail

cd "$(dirname "$0")/.."

port=4444

find_binary() {
  local name=$1 cached=$2
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
  elif [ -x "$cached" ]; then
    echo "$cached"
  fi
}

cache="$HOME/.cache/chrome-for-testing"
chromedriver=$(find_binary chromedriver "$cache/chromedriver-linux64/chromedriver")
chrome=${CHROME_EXECUTABLE:-$(find_binary google-chrome "$cache/chrome-linux64/chrome")}

if [ -z "$chromedriver" ] || [ -z "$chrome" ]; then
  cat >&2 <<'MISSING'
Chrome and chromedriver are needed, and neither is on PATH.

CI images ship both. Locally, the matching pair comes from Chrome for Testing:

    https://googlechromelabs.github.io/chrome-for-testing/

Unpack them into ~/.cache/chrome-for-testing/ and this script finds them:

    ~/.cache/chrome-for-testing/chrome-linux64/chrome
    ~/.cache/chrome-for-testing/chromedriver-linux64/chromedriver

The versions have to match: chromedriver refuses a browser it was not built
for, and says so plainly when it happens.
MISSING
  exit 1
fi

"$chromedriver" --port="$port" &
driver_pid=$!
# Without this the driver outlives a failed run and the next one finds the
# port taken, which reads as a Flutter problem and is not one.
trap 'kill "$driver_pid" 2>/dev/null || true' EXIT

# `web-server`, not `chrome`: with `-d chrome` Flutter launches a browser of
# its own and waits for its debug service, which is a second browser nobody
# drives and one more thing to hang on. Serving the build and letting
# chromedriver open it is both simpler and what CI does.
CHROME_EXECUTABLE="$chrome" flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/habit_flow_test.dart \
  --device-id=web-server \
  --browser-name=chrome \
  --chrome-binary="$chrome" \
  --driver-port="$port" \
  "${@:---headless}"
