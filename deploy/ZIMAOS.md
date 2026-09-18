# Publishing Nisabitus on ZimaOS

**English** · [Español](ZIMAOS.es.md)

> A guide to serving the web/PWA version of Nisabitus from a home ZimaOS server, for family use.

**Before you start, the most important thing:** the server **only serves the app**. Each person's data is stored in **their own browser or device**, not on ZimaOS. Two family members do not share data, and if someone deletes the app or the site's data, they lose whatever they have not exported. The backup is the **JSON export** from Settings → Your data.

## Requirements

- A published release (tag `v*`): the `release` workflow pushes the image `ghcr.io/iezappa/nisabitus`.
- ZimaOS with access to its web interface and to the internet.

## 1. Publish the image

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `release` workflow builds and pushes `ghcr.io/iezappa/nisabitus:1.0.0` and `:latest` for `amd64` and `arm64`.

The first time, make the package **public**: GitHub → your profile or organization → *Packages* → the package → *Package settings* → *Change visibility* → *Public*. If it stays private, ZimaOS cannot download it without credentials.

## 2. Install on ZimaOS

1. Download `deploy/docker-compose.yml`. It comes complete; only change the port `8081` (two places) if it is already in use on your server.
2. On ZimaOS open **App Store** → **"+"** button (top corner) → **Install a customized app**.
3. Use **Import** and paste or upload the `docker-compose.yml`. Check that the image and the port are the expected ones.
4. **Install**. When it finishes, the icon appears on the ZimaOS desktop.
5. Check that it loads at `http://<zimaos-ip>:8081`. **This URL is only for checking**, not for the family to use (see step 3).

> Menu names may vary between ZimaOS versions. If you cannot find "Install a customized app", look for the custom install or docker-compose import option in the App Store.

## 3. HTTPS for the family with Tailscale

Installing the PWA, the service worker and OPFS storage all require HTTPS. `http://IP:port` loads, but it is not installable and may lose features.

1. Install **Tailscale** from the ZimaOS App Store and sign in with your Tailscale account.
2. In the Tailscale admin console enable **MagicDNS** and **HTTPS Certificates**.
3. In a ZimaOS terminal (SSH), expose the app:

   ```bash
   tailscale serve --bg http://127.0.0.1:8081
   tailscale serve status
   ```

   If Tailscale runs as a container, run the command inside it (`docker exec -it <tailscale-container> tailscale serve --bg http://<zimaos-ip>:8081`), because `127.0.0.1` inside the container is not the host.
4. The app is then at `https://<server-name>.<your-tailnet>.ts.net/`.
5. Each family member installs Tailscale on their device and joins your tailnet (by invitation or by sharing the node).

**Always use the `ts.net` URL, at home too.** Browser storage is per origin: data saved when going in through the local IP does not appear when going in through `ts.net`, and vice versa. One URL for everything.

## 4. Install the app on each device

| Device | How |
|---|---|
| **iPhone / iPad** | Open the `ts.net` URL in **Safari** → Share → **Add to Home Screen**. Always use the Home Screen icon, not the Safari tab: that way storage is not cleared because of Safari inactivity. |
| **Android** | Chrome → menu → **Install app**. Alternative: download the APK from GitHub Releases (works without a server or Tailscale). |
| **Windows / macOS / Linux** | Chrome or Edge → install icon in the address bar. Alternative: binary from GitHub Releases. |

After installing, open the app once online and check in Settings that the JSON export works.

## 5. Data and backups

- Each person exports their JSON periodically (the app reminds them) and keeps it outside the browser: iCloud/Drive Files, or a ZimaOS shared folder.
- To move to another device: export on the old one, import on the new one.
- Reinstalling or updating the container does **not** affect the data: it is not on the server.

## 6. Update

1. Publish a new tag (`v1.1.0`). The workflow updates `:latest`.
2. On ZimaOS, open the app's settings and use the option to update/pull the image again, or over SSH:

   ```bash
   docker pull ghcr.io/iezappa/nisabitus:latest
   ```

   and restart the app from the ZimaOS interface so the container is recreated with the new image.
3. When the app is opened online, its own service worker (`sw.js`) downloads the new version in the background and the app shows **"A new version is available"**. Tapping **Update** reloads the app with the new version and deletes the previous cache.

If the new version changes the Drift schema, the migration runs on each device when the app is opened. Ask the family for a JSON export **before** publishing releases with schema changes.
