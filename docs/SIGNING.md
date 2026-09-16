# Signing the Android APK

- Alias: upload
- SHA-256: PENDING
- First version signed with this key: PENDING

`apps/client/tool/release_apk.sh` reads the first `SHA-256` line above and
refuses to upload an APK signed with any other certificate. Replace `PENDING`
with the fingerprint as `keytool` prints it (`AB:CD:...:EF`) or as lowercase
hex without colons; both are accepted. `APK_CERT_SHA256=<fingerprint>` in the
environment overrides this file for one run. While it says `PENDING`, the
script prints the fingerprint of the APK it built and stops.

The fingerprint is not secret: publish it so anyone can verify the APK. The
general procedure is the shared standard,
[`FIRMA-ANDROID.md`](https://github.com/iezappa/standardizer_multiplatform/blob/main/FIRMA-ANDROID.md)
(STACK-APPS-DINAMICAS.md §8.1); this file records what is specific to
Nisabitus. The release procedure is in [`RELEASING.md`](RELEASING.md).

## Why a fixed key

Every distributed APK is signed with **one fixed release keystore**, never the
debug key. Android refuses to install an update signed with a different key
than the installed app, and the only way out for the user is to uninstall —
which deletes every record Nisabitus keeps on the device. A lost keystore means
that for every user at once; a stolen one lets anyone ship an "update" that
installs silently over the real app.

`apps/client/android/app/build.gradle.kts` enforces this: a release build
(`flutter build apk --release`, `flutter build appbundle`, `flutter run
--release`) **fails** when `apps/client/android/key.properties` is missing.
Debug builds, `flutter run`, and the Linux and web CI jobs are unaffected.

The keystore is **never** stored in GitHub Secrets or any CI system.

## 1. Keystore location

One keystore for this app only, outside any repository, on the Linux
filesystem (not under `/mnt/*` on WSL, where `chmod` has no effect):

```text
~/.android-keystores/nisabitus/upload-keystore.jks
```

Generate it once, ever:

```bash
mkdir -p ~/.android-keystores/nisabitus
chmod 700 ~/.android-keystores ~/.android-keystores/nisabitus
keytool -genkey -v -keystore ~/.android-keystores/nisabitus/upload-keystore.jks \
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
chmod 600 ~/.android-keystores/nisabitus/upload-keystore.jks
```

Never commit it. `.gitignore` excludes `key.properties`, `*.jks` and
`*.keystore`.

## 2. Backup (before the first release)

1. In the password manager, one entry for Nisabitus with the `.jks` as an
   **attachment**, the keystore password, the key password, the alias and the
   SHA-256 fingerprint.
2. A second, **offline** copy: an encrypted USB drive or disk with the `.jks`
   and an encrypted export of that entry, kept outside the house if possible.
3. **Test the restore**: download the attachment to a temporary folder, open
   it with the stored passwords and check the fingerprint matches:

   ```bash
   keytool -list -v -keystore /path/to/restored/upload-keystore.jks -alias upload | rg 'SHA256'
   ```

A backup that was never restored is not tested. Repeat once a year. There is no
recovery without the keystore and its passwords.

## 3. Point the build at it

Create `apps/client/android/key.properties` (git-ignored), `chmod 600`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/home/<you>/.android-keystores/nisabitus/upload-keystore.jks
```

Use an absolute `storeFile`; a relative one resolves against
`apps/client/android/app/`. Better still, have the password manager's CLI write
this file just before the release and delete it afterwards (FIRMA-ANDROID.md
§5).

## 4. Record the fingerprint

```bash
keytool -list -v -keystore ~/.android-keystores/nisabitus/upload-keystore.jks -alias upload
# "SHA256: AB:CD:..."
```

Write it on the `SHA-256` line at the top of this file, and the first version
signed with it. If a release APK does not match, **do not publish it**.

## Users of APKs signed with the debug key

A signature cannot change transparently. Anyone on a debug-signed build has
to: export from Settings → Your data → Export, uninstall, install the
release-signed APK, and import the file. Say so in the release notes and record
the first release-signed version above.
