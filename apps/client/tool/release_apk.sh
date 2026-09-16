#!/usr/bin/env bash
# Builds the release APK LOCALLY, checks its signing certificate and uploads it
# to an existing GitHub Release. The keystore never leaves this machine and is
# never stored in GitHub Secrets (FIRMA-ANDROID.md, STACK-APPS-DINAMICAS.md 8.1).
#
# Run after the GitHub Release for the tag exists:
#   tool/release_apk.sh [--dry-run] vX.Y.Z
#
# Requirements: git, flutter, gh (authenticated), sha256sum, apksigner
# (PATH or ANDROID_HOME/build-tools) and android/key.properties pointing to the
# keystore. Expected fingerprint: APK_CERT_SHA256 env var, or the first
# "SHA-256" line of docs/SIGNING.md at the repo root.
# --dry-run does everything except the upload.
set -euo pipefail

OUT_DIR=""

die() { echo "error: $*" >&2; exit 1; }

# vX.Y.Z -> X.Y.Z; fails on anything else.
version_from_tag() {
  [[ $1 =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

# X.Y.Z of `version: X.Y.Z+build` in a pubspec file (same sed as the standard).
pubspec_version() {
  local v
  v="$(sed -n 's/^version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' "$1" | head -n1)"
  [ -n "$v" ] || return 1
  printf '%s\n' "$v"
}

# Lowercase hex, no colons or whitespace.
normalize() { tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]'; }

# First fingerprint on a "SHA-256" line of the signing doc (same sed as the
# standard). Prints nothing while the line says PENDING.
recorded_fingerprint() {
  sed -n 's/.*SHA-256[^0-9A-Fa-f]*\([0-9A-Fa-f:]\{64,95\}\).*/\1/p' "$1" 2>/dev/null | head -n1
}

# Expected fingerprint, normalized: APK_CERT_SHA256 wins over the signing doc.
expected_fingerprint() {
  printf '%s' "${APK_CERT_SHA256:-$(recorded_fingerprint "$1")}" | normalize
}

# apksigner from PATH, else the newest under ANDROID_HOME/build-tools.
find_apksigner() {
  command -v apksigner ||
    ls -1d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -n1
}

main() {
  local dry_run=0 TAG=""
  while (($#)); do
    case $1 in
      --dry-run) dry_run=1 ;;
      -h | --help) sed -n '2,13p' "$0"; exit 0 ;;
      -*) die "unknown option: $1" ;;
      *) [ -z "$TAG" ] || die "only one tag expected"; TAG=$1 ;;
    esac
    shift
  done
  [ -n "$TAG" ] || die "usage: tool/release_apk.sh [--dry-run] vX.Y.Z"
  local VERSION
  VERSION="$(version_from_tag "$TAG")" || die "tag must look like vX.Y.Z, got '${TAG}'"

  # Runs from any directory: the Flutter app is the parent of tool/.
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  [ -f pubspec.yaml ] || die "pubspec.yaml not found in $(pwd)"
  local REPO_ROOT SIGNING_DOC
  local APK="build/app/outputs/flutter-apk/app-release.apk"
  REPO_ROOT="$(git rev-parse --show-toplevel)" || die "not inside a git repository"
  SIGNING_DOC="$REPO_ROOT/docs/SIGNING.md"

  # 1. Clean tree and the tag checked out.
  [ -z "$(git status --porcelain)" ] || die "working tree is not clean"
  local HEAD_SHA TAG_SHA
  HEAD_SHA="$(git rev-parse HEAD)"
  TAG_SHA="$(git rev-parse "${TAG}^{commit}" 2>/dev/null)" || die "tag ${TAG} does not exist locally (git fetch --tags)"
  [ "$HEAD_SHA" = "$TAG_SHA" ] || die "HEAD is not ${TAG} (git checkout ${TAG})"

  # 2. pubspec version matches the tag.
  local PUBSPEC_VERSION
  PUBSPEC_VERSION="$(pubspec_version pubspec.yaml)" || die "no version line in pubspec.yaml"
  [ "$PUBSPEC_VERSION" = "$VERSION" ] || die "pubspec.yaml version ${PUBSPEC_VERSION} does not match ${TAG}"

  # 3. Signing config present (build.gradle.kts fails without it anyway).
  [ -f android/key.properties ] || die "android/key.properties missing (docs/SIGNING.md)"
  local STORE_FILE
  STORE_FILE="$(sed -n 's/^storeFile=//p' android/key.properties)"
  [ -f "$STORE_FILE" ] || die "keystore not found at storeFile=${STORE_FILE}"

  # 4. Tools and the release exist before the long build.
  local APKSIGNER REPO_NAME EXPECTED
  APKSIGNER="$(find_apksigner)"
  [ -x "$APKSIGNER" ] || die "apksigner not found (install build-tools, set ANDROID_HOME)"
  REPO_NAME="$(basename "$(gh repo view --json nameWithOwner -q .nameWithOwner)")" || die "gh repo view failed (gh auth login)"
  gh release view "$TAG" >/dev/null || die "GitHub Release ${TAG} not found; create it first"
  EXPECTED="$(expected_fingerprint "$SIGNING_DOC")"

  # 5. Build.
  flutter build apk --release
  [ -f "$APK" ] || die "${APK} was not produced"

  # 6. Verify the signing certificate against the recorded fingerprint.
  local ACTUAL
  ACTUAL="$("$APKSIGNER" verify --print-certs "$APK" | sed -n 's/.*certificate SHA-256 digest: //p' | head -n1 | normalize)"
  [ -n "$ACTUAL" ] || die "could not read the signing certificate from ${APK}"
  [ -n "$EXPECTED" ] || die "no expected fingerprint (APK_CERT_SHA256 or docs/SIGNING.md). This APK is signed with:
    ${ACTUAL}
If that is the release keystore (compare with keytool -list -v), record it in docs/SIGNING.md, commit, re-tag and run again."
  [ "$ACTUAL" = "$EXPECTED" ] || die "certificate fingerprint ${ACTUAL} does not match ${EXPECTED}; do NOT publish"

  # 7. Rename, checksum and upload.
  local NAME="${REPO_NAME}-${TAG}-android.apk"
  OUT_DIR="$(mktemp -d)"
  trap 'rm -rf "$OUT_DIR"' EXIT
  cp "$APK" "$OUT_DIR/$NAME"
  (cd "$OUT_DIR" && sha256sum "$NAME" > "$NAME.sha256")

  if ((dry_run)); then
    echo "Dry run: would upload ${NAME} and ${NAME}.sha256 to ${TAG} (certificate ${ACTUAL})"
    return 0
  fi
  gh release upload "$TAG" "$OUT_DIR/$NAME" "$OUT_DIR/$NAME.sha256" --clobber
  echo "Uploaded ${NAME} to ${TAG} (certificate ${ACTUAL})"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
