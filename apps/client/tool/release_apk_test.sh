#!/usr/bin/env bash
# Tests the pure checks in release_apk.sh (no git, gh, SDK or network).
#
#     tool/release_apk_test.sh

set -euo pipefail

# shellcheck source=release_apk.sh
source "$(dirname "${BASH_SOURCE[0]}")/release_apk.sh"

failures=0
check() {
  local name=$1 expected=$2 actual=$3
  if [[ $expected == "$actual" ]]; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s: expected [%s], got [%s]\n' "$name" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

check "tag v1.2.3" "1.2.3" "$(version_from_tag v1.2.3)"
check "tag without v rejected" "rejected" "$(version_from_tag 1.2.3 || echo rejected)"
check "tag with suffix rejected" "rejected" "$(version_from_tag v1.2.3-rc1 || echo rejected)"

printf 'name: x\nversion: 1.1.0+2\n' >"$tmp/pubspec.yaml"
check "pubspec version drops build" "1.1.0" "$(pubspec_version "$tmp/pubspec.yaml")"
printf 'name: x\n' >"$tmp/empty.yaml"
check "pubspec without version" "missing" "$(pubspec_version "$tmp/empty.yaml" || echo missing)"

check "fingerprint normalized" "abcd01" "$(normalize_fingerprint 'AB:CD:01')"

printf 'text\nAPK_CERT_SHA256: PENDING\n' >"$tmp/pending.md"
check "fingerprint pending" "PENDING" "$(recorded_fingerprint "$tmp/pending.md")"
printf 'APK_CERT_SHA256:   abcd01  \n' >"$tmp/set.md"
check "fingerprint recorded" "abcd01" "$(recorded_fingerprint "$tmp/set.md")"
printf 'nothing\n' >"$tmp/none.md"
check "fingerprint line missing" "missing" "$(recorded_fingerprint "$tmp/none.md" || echo missing)"

((failures == 0)) || exit 1
