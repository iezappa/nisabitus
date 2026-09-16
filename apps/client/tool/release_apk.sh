#!/usr/bin/env bash
# Builds, signs, verifies and uploads the release APK for an existing GitHub
# release.
#
#     tool/release_apk.sh [--dry-run] vX.Y.Z
#
# The keystore never leaves the maintainer's machine (see docs/RELEASING.md),
# so the APK is built here and not in CI. Before uploading, the script checks
# that the tree is clean, HEAD is the tagged commit, pubspec.yaml carries the
# tag's version, and the APK is signed with the certificate recorded in
# docs/RELEASING.md. --dry-run does everything except the upload.

set -euo pipefail

die() {
  printf 'release_apk: %s\n' "$*" >&2
  exit 1
}

# vX.Y.Z -> X.Y.Z; fails on anything else.
version_from_tag() {
  local tag=$1
  [[ $tag =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

# Prints the x.y.z part of `version: x.y.z+build` from a pubspec file.
pubspec_version() {
  local line
  line=$(grep -E '^version:' "$1" | head -n1) || return 1
  [[ $line =~ ^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+) ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

# Lowercase hex, no colons or spaces.
normalize_fingerprint() {
  printf '%s\n' "$1" | tr -d ': ' | tr '[:upper:]' '[:lower:]'
}

# Prints the value of the `APK_CERT_SHA256:` line in a docs file.
recorded_fingerprint() {
  local line
  line=$(grep -E '^APK_CERT_SHA256:' "$1" | head -n1) || return 1
  line=${line#APK_CERT_SHA256:}
  line=${line//[[:space:]]/}
  [[ -n $line ]] || return 1
  printf '%s\n' "$line"
}

# Newest apksigner under $ANDROID_HOME (or $ANDROID_SDK_ROOT).
find_apksigner() {
  local sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
  [[ -n $sdk ]] || return 1
  local found
  found=$(printf '%s\n' "$sdk"/build-tools/*/apksigner | sort -V | tail -n1)
  [[ -x $found ]] || return 1
  printf '%s\n' "$found"
}

main() {
  local dry_run=0 tag=""
  while (($#)); do
    case $1 in
      --dry-run) dry_run=1 ;;
      -h | --help)
        sed -n '2,11p' "$0"
        exit 0
        ;;
      -*) die "unknown option: $1" ;;
      *)
        [[ -z $tag ]] || die "only one tag expected"
        tag=$1
        ;;
    esac
    shift
  done
  [[ -n $tag ]] || die "usage: tool/release_apk.sh [--dry-run] vX.Y.Z"

  local version
  version=$(version_from_tag "$tag") || die "tag must look like vX.Y.Z, got '$tag'"

  local client repo
  client=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  repo=$(git -C "$client" rev-parse --show-toplevel) || die "not inside a git repository"
  local docs="$repo/docs/RELEASING.md"
  local pubspec="$client/pubspec.yaml"

  [[ -z $(git -C "$repo" status --porcelain) ]] ||
    die "working tree is not clean; commit or stash first"

  local tag_commit head
  tag_commit=$(git -C "$repo" rev-parse --verify --quiet "$tag^{commit}") ||
    die "tag $tag does not exist locally (git fetch --tags?)"
  head=$(git -C "$repo" rev-parse HEAD)
  [[ $head == "$tag_commit" ]] ||
    die "HEAD ($head) is not $tag ($tag_commit); git checkout $tag first"

  local pub
  pub=$(pubspec_version "$pubspec") || die "no version line in $pubspec"
  [[ $pub == "$version" ]] ||
    die "pubspec.yaml version is $pub but the tag is $tag"

  [[ -f $client/android/key.properties ]] ||
    die "android/key.properties is missing; see docs/RELEASING.md"

  local expected
  expected=$(recorded_fingerprint "$docs") ||
    die "no APK_CERT_SHA256 line in $docs"

  gh auth status >/dev/null 2>&1 || die "gh is not authenticated; run gh auth login"
  gh release view "$tag" >/dev/null 2>&1 ||
    die "GitHub release $tag does not exist; create it first"

  local apksigner
  apksigner=$(find_apksigner) ||
    die "apksigner not found under \$ANDROID_HOME/build-tools; install the Android SDK build-tools"

  (cd "$client" && flutter build apk --release)

  local apk="$client/build/app/outputs/flutter-apk/app-release.apk"
  [[ -f $apk ]] || die "build finished but $apk is missing"

  local actual
  actual=$("$apksigner" verify --print-certs "$apk" |
    sed -n 's/^Signer #1 certificate SHA-256 digest:[[:space:]]*//p' | head -n1)
  [[ -n $actual ]] || die "could not read the signing certificate from $apk"
  actual=$(normalize_fingerprint "$actual")

  if [[ $expected == PENDING ]]; then
    die "no fingerprint recorded yet. This APK is signed with:
    $actual
Check it is the release keystore, write it into $docs as
    APK_CERT_SHA256: $actual
commit, re-tag, and run this again."
  fi
  [[ $(normalize_fingerprint "$expected") == "$actual" ]] ||
    die "APK certificate $actual does not match the recorded $expected. Do NOT publish."

  local out="$client/build/release"
  local name="nisabitus-$tag.apk"
  mkdir -p "$out"
  cp "$apk" "$out/$name"
  (cd "$out" && sha256sum "$name" >"$name.sha256")

  if ((dry_run)); then
    printf 'Dry run: would upload %s and %s.sha256 to %s\n' "$out/$name" "$out/$name" "$tag"
    return 0
  fi
  gh release upload "$tag" "$out/$name" "$out/$name.sha256" --clobber
  printf 'Uploaded %s to %s\n' "$name" "$tag"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
