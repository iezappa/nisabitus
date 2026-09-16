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

## 1. Generate the keystore (once, ever)

```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Never commit it. `.gitignore` excludes `key.properties`, `*.jks` and
`*.keystore`.

## 2. Back it up offline

Store the `.jks` file, both passwords and the alias in a password manager
(as an attachment) **and** in a second, offline location. There is no
recovery if it is lost.

## 3. Record the certificate fingerprint

The SHA-256 fingerprint is not secret. Record it below and compare it on
every release:

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload   # SHA256:
apksigner verify --print-certs app-release.apk                 # SHA-256 digest
```

| Certificate | SHA-256 |
|---|---|
| upload (release) | _not generated yet_ |

If a release APK does not match, **do not publish it**.

## 4. Local builds

Create `apps/client/android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` resolves relative to `apps/client/android/app/`.

## 5. CI secrets

In GitHub → Settings → Secrets and variables → Actions:

| Secret | Content |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` (macOS: `base64 -i upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | alias (`upload`) |
| `ANDROID_KEY_PASSWORD` | key password |

A release workflow must check that all four are set and fail otherwise, then
decode the keystore into `android/app/upload-keystore.jks` and write
`android/key.properties` before building. No silent fallback to debug.

## Users of APKs signed with the debug key

A signature cannot change transparently. Anyone on a debug-signed build has
to: export from Settings → Your data → Export, uninstall, install the
release-signed APK, and import the file. Say so in the release notes.
