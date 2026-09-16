#!/usr/bin/env bash
# Tests the pure checks in release_apk.sh (no git, gh, SDK or network).
#
#     tool/release_apk_test.sh

set -euo pipefail

here="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=release_apk.sh
source "$here/release_apk.sh"

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

hex=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
colons=01:23:45:67:89:AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89:AB:CD:EF

check "tag v1.2.3" "1.2.3" "$(version_from_tag v1.2.3)"
check "tag without v rejected" "rejected" "$(version_from_tag 1.2.3 || echo rejected)"
check "tag with suffix rejected" "rejected" "$(version_from_tag v1.2.3-rc1 || echo rejected)"

printf 'name: x\nversion: 1.1.0+2\n' >"$tmp/pubspec.yaml"
check "pubspec version drops build" "1.1.0" "$(pubspec_version "$tmp/pubspec.yaml")"
printf 'name: x\n' >"$tmp/empty.yaml"
check "pubspec without version" "missing" "$(pubspec_version "$tmp/empty.yaml" || echo missing)"

check "fingerprint normalized" "abcd01" "$(printf 'AB:CD:01 \n' | normalize)"

printf '# Signing\n\n- Alias: upload\n- SHA-256: %s\n' "$colons" >"$tmp/keytool.md"
check "keytool fingerprint recorded" "$hex" "$(unset APK_CERT_SHA256; expected_fingerprint "$tmp/keytool.md")"
printf -- '- SHA-256: %s\n' "$hex" >"$tmp/hex.md"
check "apksigner fingerprint recorded" "$hex" "$(unset APK_CERT_SHA256; expected_fingerprint "$tmp/hex.md")"
printf -- '- SHA-256: PENDING\n' >"$tmp/pending.md"
check "pending gives no fingerprint" "" "$(unset APK_CERT_SHA256; expected_fingerprint "$tmp/pending.md")"
check "missing doc gives no fingerprint" "" "$(unset APK_CERT_SHA256; expected_fingerprint "$tmp/nope.md")"
check "env var overrides doc" "$hex" "$(APK_CERT_SHA256=$colons expected_fingerprint "$tmp/pending.md")"
check "committed docs/SIGNING.md parses" "" \
  "$(unset APK_CERT_SHA256; expected_fingerprint "$here/../../../docs/SIGNING.md")"
check "committed docs/SIGNING.md has a SHA-256 line" "1" \
  "$(grep -c '^- SHA-256:' "$here/../../../docs/SIGNING.md")"

((failures == 0)) || exit 1
