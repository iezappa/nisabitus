# Nisabitus

**English** · [Español](README.es.md)

Habits, streaks, sleep, journal, tasks, nutrition, hydration, training, meditation and medication in a single app. Private and offline: no accounts, no server, no analytics.

- **Downloads:** https://github.com/iezappa/nisabitus/releases/latest
- **Web version (iPhone, iPad and any browser):** https://iezappa.github.io/nisabitus/ (or the `ts.net` URL of your ZimaOS server, if the family uses one: pick one and do not change it)

> [!WARNING]
> **Your data lives ONLY on your device.**
>
> *Tus datos viven SOLO en tu dispositivo. Exporta un respaldo con frecuencia: Ajustes → Tus datos → Exportar.*
>
> - It is not stored on the developer's servers. Nor on the ZimaOS server: that server only delivers the app, it stores nothing of yours.
> - If you uninstall the app, lose or reset the device, or clear the browser's or Safari's data, **your data is lost forever**.
> - The only backup is the one you make yourself.
>
> **Back up often (recommended: once a week):**
>
> 1. Open the app → **Settings** → **Your data** → **Export**.
> 2. Save the `.json` file somewhere safe **off this device**: iCloud Drive, Google Drive, OneDrive, an email to yourself or another device.
>
> **To recover your data** (new device, reinstall):
>
> 1. Install the app and open it.
> 2. **Settings** → **Your data** → **Import** → choose your latest `.json` file.
> 3. Confirm. The data in the file replaces whatever is in the app.

## Contents

- [Self-hosted server (ZimaOS)](#self-hosted-server-zimaos)
- [Windows](#windows)
- [Ubuntu (Linux)](#ubuntu-linux)
- [macOS](#macos)
- [iPhone and iPad](#iphone-and-ipad)
- [Android](#android)
- [Updates](#updates)
- [Privacy](#privacy)
- [For developers](#for-developers)

---

## Self-hosted server (ZimaOS)

Only **whoever runs the server** needs this. The rest of the family can skip to their device.

The server publishes the web version of the app so the family can use it from the browser or install it as an app (PWA). Summary:

1. Publish a version with a tag (`vX.Y.Z`): GitHub builds the image `ghcr.io/iezappa/nisabitus`. The first time, make the package public on GitHub.
2. Import `deploy/docker-compose.yml` (already complete; port 8081) into ZimaOS: **App Store** → **+** → **Install a customized app** → **Import**.
3. Install **Tailscale** on ZimaOS, enable HTTPS and expose the app with `tailscale serve`. The app is then at `https://<your-server>.<your-tailnet>.ts.net/`.
4. Each family member installs Tailscale on their device and joins the tailnet.

**Full guide:** [`deploy/ZIMAOS.md`](deploy/ZIMAOS.md).

**Requirements:** ZimaOS with internet access and a Tailscale account.

**Updating:** publish a new tag and pull the `:latest` image again on ZimaOS (details in the guide). When they open the app online, users see **"A new version is available"** and tap **Update**.

**Your data:** updating, reinstalling or deleting the container does **not** affect anyone's data, because it is not on the server. **Always use the same URL** (`https://<your-server>.<your-tailnet>.ts.net/`), at home too: if you go in through the local IP, the browser treats it as a different site and the app will appear empty.

---

## Windows

**Requirements:** 64-bit Windows 10 or 11.

**Install:**

1. Go to https://github.com/iezappa/nisabitus/releases/latest.
2. Under **Assets**, download `nisabitus-vX.Y.Z-windows-x64.zip`.
3. Right-click the `.zip` → **Extract All** → choose a permanent folder, for example `Documents\Nisabitus`. Do not run it from inside the `.zip`.
4. Open the folder and double-click the `.exe` file.
5. Windows will show **"Windows protected your PC"** because the app is not signed. Click **More info** → **Run anyway**. This only happens the first time.
6. Optional: right-click the `.exe` → **Show more options** → **Send to** → **Desktop (create shortcut)**.

> Do not move or delete the other files in the folder (`.dll` files, the `data` folder): the `.exe` needs them.

**Update:**

1. Make a backup (**Settings → Your data → Export**).
2. Close the app.
3. Download the new `.zip` and extract it **into the same folder**, replacing the files.

**Your data:** it is stored in your Windows user profile, outside the app folder, so replacing the folder does not delete it. It is lost if you format the computer or switch Windows users: keep the backup in OneDrive, Google Drive or on another device.

---

## Ubuntu (Linux)

**Requirements:** 64-bit (x86_64) Ubuntu 22.04 or later. There is no ARM version.

**Install:**

1. Install the system libraries (once):

   ```bash
   sudo apt update
   sudo apt install libgtk-3-0
   ```

2. Download `nisabitus-vX.Y.Z-linux-x64.tar.gz` from https://github.com/iezappa/nisabitus/releases/latest.
3. Extract it into a permanent folder and run it:

   ```bash
   mkdir -p ~/Apps/nisabitus
   tar -xzf ~/Downloads/nisabitus-vX.Y.Z-linux-x64.tar.gz -C ~/Apps/nisabitus
   ls ~/Apps/nisabitus        # the executable is the file without an extension next to the data and lib folders
   ~/Apps/nisabitus/<executable>
   ```

   If your downloads folder has another name (for example `Descargas`), change the path.

4. Optional, to see it in the applications menu, create `~/.local/share/applications/nisabitus.desktop`:

   ```ini
   [Desktop Entry]
   Type=Application
   Name=Nisabitus
   Exec=/home/<your-user>/Apps/nisabitus/<executable>
   Icon=/home/<your-user>/Apps/nisabitus/data/flutter_assets/<icon-path>.png
   Terminal=false
   Categories=Utility;
   ```

   Use full paths (no `~`). If you have no icon, delete the `Icon=` line.

**Update:**

1. Make a backup (**Settings → Your data → Export**) and close the app.
2. Delete the contents of `~/Apps/nisabitus` and extract the new `.tar.gz` there (step 3).

**Your data:** it is stored in your home folder (usually under `~/.local/share/`), not in `~/Apps/nisabitus`, so replacing the app does not delete it. It is lost if you reinstall Ubuntu or delete your home folder: keep the backup off the computer.

---

## macOS

**Requirements:** a Mac with a recent macOS (Intel or Apple Silicon).

**Install:**

1. Download `nisabitus-vX.Y.Z-macos.zip` from https://github.com/iezappa/nisabitus/releases/latest.
2. Double-click the `.zip`: the app (`.app`) appears.
3. Drag the app into the **Applications** folder.
4. The app is not signed, so macOS blocks it the first time. Open it like this:
   - **Right-click** (or Control-click) the app → **Open** → **Open**.
   - If the option does not appear, try opening it normally, go to **System Settings** → **Privacy & Security**, scroll down to the notice about the app and click **Open Anyway**. Confirm with your password.
5. If macOS says the app **"is damaged"**, open **Terminal** and run (adjust the app name):

   ```bash
   xattr -dr com.apple.quarantine "/Applications/<Name>.app"
   ```

**Update:**

1. Make a backup (**Settings → Your data → Export**) and close the app.
2. Download the new `.zip`, replace the app in **Applications** and repeat step 4 if macOS blocks it again.

**Your data:** it is stored in your macOS user account (inside `~/Library`), not inside the app, so replacing the app does not delete it. It is lost if you delete your user account or reset the Mac: keep the backup in iCloud Drive or on another device.

---

## iPhone and iPad

There is no App Store version. You use the **web version installed on the Home Screen**, which works like an app. **It works offline after you have opened it once with internet** (the first launch downloads the app to the device; close and reopen the app before trying it offline).

**Requirements:** iOS or iPadOS 17 or later (recommended), **Safari**. If the app is served from the family server, Tailscale installed and connected as well.

**Install:**

1. Open **Safari**. It has to be Safari: it does not install properly from other browsers.
2. Go to https://iezappa.github.io/nisabitus/ (or the `ts.net` URL of your ZimaOS server, if the family uses one: pick one and do not change it).
3. Tap the **Share** button (square with an upward arrow).
4. Scroll down and tap **Add to Home Screen**. If you do not see it, tap **Edit Actions** and add it.
5. Tap **Add**.
6. **Always open the app from the Home Screen icon**, not from a Safari tab.

> **Important:** the icon app and the Safari tab store their data separately. Data you enter in Safari will not appear in the icon app, and vice versa. Also, Safari may delete the data of sites you do not use for several days; the icon app, used regularly, does not. Use only the icon.

> **Always use the same address** (https://iezappa.github.io/nisabitus/ (or the `ts.net` URL of your ZimaOS server, if the family uses one: pick one and do not change it)). If you go in through another address, the app will appear empty.

**Update:** open the app online; when **"A new version is available"** appears, tap **Update**. If it does not appear, close the app completely (swipe up) and open it again.

> If iOS deletes the site's data (or you delete the icon), the offline copy is deleted too: open the app once more with internet.

**Your data:** it is stored only on this iPhone or iPad, inside the icon app. It is lost if you delete the icon from the Home Screen, clear website data in **Settings → Safari** or reset the device. Export and save the file in **Files → iCloud Drive**. Deleting the icon is the same as uninstalling: **export first**.

---

## Android

There are two options. Choose **one** and stick with it.

> **The app installed from the APK and the app installed from Chrome store their data separately.** They do not share it. If you switch from one to the other, export in the old one and import in the new one.

### Option 1: APK (recommended, needs no server and no internet)

**Requirements:** Android 7 or later (recommended).

**Install:**

1. On the phone, open https://github.com/iezappa/nisabitus/releases/latest.
2. Under **Assets**, download `nisabitus-vX.Y.Z-android.apk`.
3. Open the downloaded file. Android will ask for permission to install apps from unknown sources: tap **Settings** → turn on **Allow from this source** → go back.
4. Tap **Install**. If Google Play Protect shows a warning, choose **Install anyway** (the app does not come from the Play Store).

**Update:** the app tells you with a **"A new version is available"** notice when you open it online. Tap **Download**, make a backup if the notice asks for one and install the APK over the existing app. **Do not uninstall the previous app**: uninstalling deletes the data. Every version is signed with the same key, so it installs over the old one without trouble. If Android says the package "conflicts" with the existing one, **do not uninstall**: export your data and tell the developer.

**Automatic updates (optional) with Obtainium:**

1. Install Obtainium from https://github.com/ImranR98/Obtainium/releases (or F-Droid).
2. In Obtainium tap **Add App** and paste `https://github.com/iezappa/nisabitus`.
3. Tap **Add**. Obtainium notifies you when there is a new version and installs it over the existing app.

> **If you installed the app before the first version signed with the release keystore (see [`docs/SIGNING.md`](docs/SIGNING.md)):** that version used a different signature and cannot be updated in place. Once only: **Export** → uninstall → install the new APK → **Import**. If you do not export before uninstalling, you lose your data.

**Your data:** it is stored inside the app. It is lost if you uninstall it, tap **Clear storage** in the app's settings or reset the phone. Keep the backup in Google Drive or on another device.

### Option 2: install from Chrome (PWA)

1. Open **Chrome** and go to https://iezappa.github.io/nisabitus/ (or the `ts.net` URL of your ZimaOS server, if the family uses one: pick one and do not change it).
2. Menu **⋮** → **Install app** (or **Add to Home screen** → **Install**).
3. Open the app from its icon and always use the same address.

It works offline after you have opened it once with internet.

**Update:** when you open the app online, **"A new version is available"** appears: tap **Update** and the app reloads.

**Your data:** it is stored in Chrome for that address. It is lost if you uninstall the app, clear Chrome's or the site's data, or reset the phone.

---

## Updates

The app checks for a new version when it opens online (on computers and Android, at most every 6 hours). Offline nothing happens: it keeps working the same (on the web version, after it has been opened once with internet).

| Device | How you find out | How you update |
|---|---|---|
| iPhone and iPad | "A new version is available" notice | Tap **Update**. If it does not appear, close the app completely (swipe up) and open it again. |
| Android (APK) | "A new version is available" notice | **Download** and install over the existing app, or automatically with Obtainium (see [Android](#android)). |
| Android (Chrome) and browser | "A new version is available" notice | Tap **Update**. |
| Windows, Ubuntu, macOS | "A new version is available" notice | Open the release page; follow the **Update** steps for your system. |

- **If the notice asks for a backup**, the new version changes how data is stored: tap **Export** and save the file **before** updating.
- After updating, the app shows **What's new** with the changes in that version.

---

## Privacy

Nisabitus has no accounts, analytics or advertising, and your data does not leave your device. To delete it: **Settings → Your data → Delete all my data**.

- [Privacy policy](PRIVACY.md)
- [Terms of use](TERMS.md)
- Español: [Política de privacidad](PRIVACY.es.md) · [Términos de uso](TERMS.es.md)

Contact: Zeke Zappa Developments (iezappa) — https://github.com/iezappa/nisabitus/issues

---

## For developers

Stack and rules: `STACK-APPS-DINAMICAS.md` (profile A) in the Estandarizador repo. Open items and decisions: [`TODO.md`](TODO.md); releasing: [`docs/RELEASING.md`](docs/RELEASING.md). The Flutter project is in `apps/client`.

```bash
cd apps/client
flutter pub get
dart run build_runner build      # Drift generated code
flutter test
flutter run -d chrome            # or linux / windows / macos / an Android device
```

Test the web image locally:

```bash
docker build -f deploy/Dockerfile -t nisabitus .
docker run --rm -p 8080:8080 nisabitus    # http://localhost:8080
```

Publish a version (Releases with Linux, Windows, macOS and web, and the image `ghcr.io/iezappa/nisabitus`; GitHub Pages is published on every push to `main` by `deploy-pages.yml`):

```bash
# The pubspec.yaml version (x.y.z+build) and web/update.json must match the tag
git tag vX.Y.Z && git push origin vX.Y.Z
```

CI does not build the APK: after the release is created, the maintainer signs it locally with the release keystore and uploads it with `tool/release_apk.sh vX.Y.Z` (run from `apps/client`). The keystore is not on GitHub. Expected SHA-256 fingerprint of the certificate: `the one recorded in [`docs/SIGNING.md`](docs/SIGNING.md) (pending until the keystore is generated)` (check with `apksigner verify --print-certs`).

The web version ships its own service worker (`web/sw.js`, registered in `web/flutter_bootstrap.js`); CI and the Dockerfile run `tool/generate_sw.sh` after `flutter build web`. If a release breaks the service worker, publish the kill switch (`web/sw-killswitch.js`, instructions inside).

If the version changes the Drift schema, bump `schemaVersion`, add the migration test and set `"schemaChange": true` in `web/update.json`: the update notice will ask for an export before updating.
