# Releasing the Android APK

Every distributed APK is signed with **one fixed release keystore**, never the
debug key. Android refuses to install an update signed with a different key
than the installed app, and the only way out for the user is to uninstall —
which deletes every record Nisabitus keeps on the device. Losing the keystore
means the same thing for every user at once.

`android/app/build.gradle.kts` enforces this: a release build
(`flutter build apk --release`, `flutter build appbundle`, `flutter run
--release`) **fails** when `apps/client/android/key.properties` is missing.
Debug builds, `flutter run`, and the Linux and web CI jobs are unaffected.

The keystore is **never** stored in GitHub Secrets or any CI system. APKs are
built and signed on the maintainer's machine and attached to the GitHub
release with `apps/client/tool/release_apk.sh`. The general procedure is the
shared standard in
[`FIRMA-ANDROID.md`](https://github.com/iezappa/standardizer_multiplatform/blob/main/FIRMA-ANDROID.md);
this file records what is specific to Nisabitus.

## 1. Generate the keystore (once, ever)

Keep it on the Linux filesystem (not under `/mnt/*` on WSL, where permissions
are not enforced):

```bash
mkdir -p ~/.android-keystores/nisabitus && chmod 700 ~/.android-keystores/nisabitus
keytool -genkey -v -keystore ~/.android-keystores/nisabitus/upload-keystore.jks \
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
chmod 600 ~/.android-keystores/nisabitus/upload-keystore.jks
```

Never commit it. `.gitignore` excludes `key.properties`, `*.jks` and
`*.keystore`.

## 2. Back it up

Store the `.jks` file, both passwords and the alias in a password manager (as
an attachment) **and** in a second, offline copy (e.g. an encrypted USB drive).
There is no recovery if it is lost.

## 3. Point the build at it

Create `apps/client/android/key.properties` (git-ignored), `chmod 600`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/home/<you>/.android-keystores/nisabitus/upload-keystore.jks
```

Use an absolute `storeFile`; a relative one resolves against
`apps/client/android/app/`.

## 4. Record the certificate fingerprint

The SHA-256 fingerprint is not secret. `release_apk.sh` reads the line below
and refuses to upload an APK signed with anything else. While it says
`PENDING`, the script prints the fingerprint of the APK it built and stops.

```bash
keytool -list -v -keystore ~/.android-keystores/nisabitus/upload-keystore.jks -alias upload
```

Write it as lowercase hex without colons:

APK_CERT_SHA256: PENDING

If a release APK does not match, **do not publish it**.

## 5. Release procedure

Requirements: the Android SDK with build-tools (`$ANDROID_HOME` set, for
`apksigner`), Flutter, and an authenticated `gh`.

1. Bump `version:` in `apps/client/pubspec.yaml`, commit.
2. Tag and push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. Create the GitHub release. A release workflow that builds the other
   artifacts is still pending (P1, see `TODO.md`); until then create it by hand
   with `gh release create vX.Y.Z`.
4. With a clean tree checked out at the tag:

   ```bash
   cd apps/client
   tool/release_apk.sh --dry-run vX.Y.Z   # builds and verifies, no upload
   tool/release_apk.sh vX.Y.Z
   ```

   It checks the tree, the tag, the pubspec version, `key.properties`, `gh`
   and the release; builds; verifies the certificate; and uploads
   `nisabitus-vX.Y.Z.apk` plus its `.sha256`.

The script's pure checks are covered by `tool/release_apk_test.sh`.

## Users of APKs signed with the debug key

A signature cannot change transparently. Anyone on a debug-signed build has
to: export from Settings → Your data → Export, uninstall, install the
release-signed APK, and import the file. Say so in the release notes.
