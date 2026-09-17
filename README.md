# Nisabitus

Hábitos, rachas, sueño, diario, tareas, alimentación, hidratación, entrenamiento, meditación y medicación en una sola app. Privada y sin conexión: sin cuentas, sin servidor, sin analítica.

- **Descargas:** https://github.com/iezappa/nisabitus/releases/latest
- **Versión web (iPhone, iPad y cualquier navegador):** https://iezappa.github.io/nisabitus/ (o la URL `ts.net` de tu servidor ZimaOS, si la familia usa uno: elige una y no la cambies)

> [!WARNING]
> **Tus datos viven SOLO en tu dispositivo.**
>
> *Your data lives ONLY on your device. Export a backup regularly: Settings → Your data → Export.*
>
> - No se guardan en los servidores del desarrollador. Tampoco en el servidor ZimaOS: ese servidor solo entrega la app, no guarda nada tuyo.
> - Si desinstalas la app, pierdes o reseteas el dispositivo, o borras los datos del navegador o de Safari, **tus datos se pierden para siempre**.
> - La única copia de seguridad es la que hagas tú.
>
> **Haz un respaldo con frecuencia (recomendado: una vez por semana):**
>
> 1. Abre la app → **Ajustes** → **Tus datos** → **Exportar**.
> 2. Guarda el archivo `.json` en un lugar seguro **fuera de este dispositivo**: iCloud Drive, Google Drive, OneDrive, un correo a ti mismo u otro dispositivo.
>
> **Para recuperar tus datos** (dispositivo nuevo, reinstalación):
>
> 1. Instala la app y ábrela.
> 2. **Ajustes** → **Tus datos** → **Importar** → elige tu último archivo `.json`.
> 3. Confirma. Los datos del archivo reemplazan a los que haya en la app.

## Índice

- [Servidor propio (ZimaOS)](#servidor-propio-zimaos)
- [Windows](#windows)
- [Ubuntu (Linux)](#ubuntu-linux)
- [macOS](#macos)
- [iPhone y iPad](#iphone-y-ipad)
- [Android](#android)
- [Actualizaciones](#actualizaciones)
- [Privacidad](#privacidad)
- [Para desarrolladores](#para-desarrolladores)

---

## Servidor propio (ZimaOS)

Solo lo necesita **quien administra el servidor**. El resto de la familia salta a su dispositivo.

El servidor publica la versión web de la app para que la familia la use desde el navegador o la instale como app (PWA). Resumen:

1. Publicar una versión con un tag (`vX.Y.Z`): GitHub construye la imagen `ghcr.io/iezappa/nisabitus`. La primera vez, hacer público el paquete en GitHub.
2. Importar `deploy/docker-compose.yml` (ya completo; puerto 8081) en ZimaOS: **App Store** → **+** → **Install a customized app** → **Import**.
3. Instalar **Tailscale** en ZimaOS, habilitar HTTPS y exponer la app con `tailscale serve`. La app queda en `https://<tu-servidor>.<tu-tailnet>.ts.net/`.
4. Cada familiar instala Tailscale en su dispositivo y se une a la tailnet.

**Guía completa:** [`deploy/ZIMAOS.md`](deploy/ZIMAOS.md).

**Requisitos:** ZimaOS con acceso a internet y una cuenta de Tailscale.

**Actualizar:** publicar un tag nuevo y volver a descargar la imagen `:latest` en ZimaOS (detalle en la guía). Al abrir la app con conexión, los usuarios ven **"Hay una versión nueva"** y tocan **Actualizar**.

**Tus datos:** actualizar, reinstalar o borrar el contenedor **no** afecta los datos de nadie, porque no están en el servidor. Usa **siempre la misma URL** (`https://<tu-servidor>.<tu-tailnet>.ts.net/`), también dentro de casa: si entras por la IP local, el navegador lo trata como otro sitio y la app aparecerá vacía.

---

## Windows

**Requisitos:** Windows 10 u 11 de 64 bits.

**Instalar:**

1. Entra a https://github.com/iezappa/nisabitus/releases/latest.
2. En **Assets**, descarga `nisabitus-vX.Y.Z-windows-x64.zip`.
3. Clic derecho sobre el `.zip` → **Extraer todo** → elige una carpeta fija, por ejemplo `Documentos\Nisabitus`. No lo ejecutes desde dentro del `.zip`.
4. Abre la carpeta y haz doble clic en el archivo `.exe`.
5. Windows mostrará **"Windows protegió su PC"** porque la app no está firmada. Haz clic en **Más información** → **Ejecutar de todas formas**. Solo pasa la primera vez.
6. Opcional: clic derecho sobre el `.exe` → **Mostrar más opciones** → **Enviar a** → **Escritorio (crear acceso directo)**.

> No muevas ni borres los demás archivos de la carpeta (`.dll`, carpeta `data`): el `.exe` los necesita.

**Actualizar:**

1. Haz un respaldo (**Ajustes → Tus datos → Exportar**).
2. Cierra la app.
3. Descarga el `.zip` nuevo y extráelo **en la misma carpeta**, reemplazando los archivos.

**Tus datos:** se guardan en tu usuario de Windows, fuera de la carpeta de la app, así que reemplazar la carpeta no los borra. Sí se pierden si formateas el equipo o cambias de usuario de Windows: guarda el respaldo en OneDrive, Google Drive u otro dispositivo.

---

## Ubuntu (Linux)

**Requisitos:** Ubuntu 22.04 o posterior, de 64 bits (x86_64). No hay versión para ARM.

**Instalar:**

1. Instala las bibliotecas del sistema (una sola vez):

   ```bash
   sudo apt update
   sudo apt install libgtk-3-0
   ```

2. Descarga `nisabitus-vX.Y.Z-linux-x64.tar.gz` desde https://github.com/iezappa/nisabitus/releases/latest.
3. Extrae en una carpeta fija y ejecuta:

   ```bash
   mkdir -p ~/Apps/nisabitus
   tar -xzf ~/Descargas/nisabitus-vX.Y.Z-linux-x64.tar.gz -C ~/Apps/nisabitus
   ls ~/Apps/nisabitus        # el ejecutable es el archivo sin extensión junto a las carpetas data y lib
   ~/Apps/nisabitus/<ejecutable>
   ```

   Si tu carpeta de descargas se llama `Downloads`, cambia la ruta.

4. Opcional, para verla en el menú de aplicaciones, crea `~/.local/share/applications/nisabitus.desktop`:

   ```ini
   [Desktop Entry]
   Type=Application
   Name=Nisabitus
   Exec=/home/<tu-usuario>/Apps/nisabitus/<ejecutable>
   Icon=/home/<tu-usuario>/Apps/nisabitus/data/flutter_assets/<ruta-del-icono>.png
   Terminal=false
   Categories=Utility;
   ```

   Usa rutas completas (sin `~`). Si no tienes ícono, borra la línea `Icon=`.

**Actualizar:**

1. Haz un respaldo (**Ajustes → Tus datos → Exportar**) y cierra la app.
2. Borra el contenido de `~/Apps/nisabitus` y extrae ahí el `.tar.gz` nuevo (paso 3).

**Tus datos:** se guardan en tu carpeta personal (normalmente bajo `~/.local/share/`), no en `~/Apps/nisabitus`, así que reemplazar la app no los borra. Se pierden si reinstalas Ubuntu o borras tu carpeta personal: guarda el respaldo fuera del equipo.

---

## macOS

**Requisitos:** un Mac con macOS reciente (Intel o Apple Silicon).

**Instalar:**

1. Descarga `nisabitus-vX.Y.Z-macos.zip` desde https://github.com/iezappa/nisabitus/releases/latest.
2. Haz doble clic en el `.zip`: aparece la app (`.app`).
3. Arrastra la app a la carpeta **Aplicaciones**.
4. La app no está firmada, así que macOS la bloquea la primera vez. Ábrela así:
   - **Clic derecho** (o Control + clic) sobre la app → **Abrir** → **Abrir**.
   - Si no aparece la opción, intenta abrirla normalmente, ve a **Ajustes del Sistema** → **Privacidad y seguridad**, baja hasta el aviso sobre la app y pulsa **Abrir igualmente**. Confirma con tu contraseña.
5. Si macOS dice que la app **"está dañada"**, abre **Terminal** y ejecuta (ajusta el nombre de la app):

   ```bash
   xattr -dr com.apple.quarantine "/Applications/<Nombre>.app"
   ```

**Actualizar:**

1. Haz un respaldo (**Ajustes → Tus datos → Exportar**) y cierra la app.
2. Descarga el `.zip` nuevo, reemplaza la app en **Aplicaciones** y repite el paso 4 si macOS vuelve a bloquearla.

**Tus datos:** se guardan en tu usuario de macOS (dentro de `~/Library`), no dentro de la app, así que reemplazarla no los borra. Se pierden si borras tu usuario o reseteas el Mac: guarda el respaldo en iCloud Drive u otro dispositivo.

---

## iPhone y iPad

No hay versión en App Store. Se usa la **versión web instalada en la pantalla de inicio**, que funciona como una app. **Funciona sin conexión después de abrirla una vez con internet** (la primera apertura descarga la app al dispositivo; cierra y vuelve a abrir la app antes de probar sin conexión).

**Requisitos:** iOS o iPadOS 17 o posterior (recomendado), **Safari**. Si la app se sirve desde el servidor familiar, también Tailscale instalado y conectado.

**Instalar:**

1. Abre **Safari**. Tiene que ser Safari: desde otros navegadores no se instala bien.
2. Entra a https://iezappa.github.io/nisabitus/ (o la URL `ts.net` de tu servidor ZimaOS, si la familia usa uno: elige una y no la cambies).
3. Toca el botón **Compartir** (cuadrado con flecha hacia arriba).
4. Baja y toca **Agregar a inicio**. Si no lo ves, toca **Editar acciones** y agrégalo.
5. Toca **Agregar**.
6. **Abre la app siempre desde el ícono de la pantalla de inicio**, no desde una pestaña de Safari.

> **Importante:** la app del ícono y la pestaña de Safari guardan sus datos por separado. Si cargas datos en Safari no aparecerán en el ícono, y viceversa. Además, Safari puede borrar los datos de sitios que no usas durante varios días; la app del ícono, usada con regularidad, no. Usa solo el ícono.

> Usa **siempre la misma dirección** (https://iezappa.github.io/nisabitus/ (o la URL `ts.net` de tu servidor ZimaOS, si la familia usa uno: elige una y no la cambies)). Si entras por otra dirección, la app aparecerá vacía.

**Actualizar:** abre la app con conexión; cuando aparezca **"Hay una versión nueva"**, toca **Actualizar**. Si no aparece, ciérrala por completo (deslizar hacia arriba) y ábrela otra vez.

> Si iOS borra los datos del sitio (o borras el ícono), también se borra la copia sin conexión: vuelve a abrir la app una vez con internet.

**Tus datos:** se guardan solo en este iPhone o iPad, dentro de la app del ícono. Se pierden si borras el ícono de la pantalla de inicio, si borras los datos de sitios web en **Ajustes → Safari** o si reseteas el dispositivo. Exporta y guarda el archivo en **Archivos → iCloud Drive**. Borrar el ícono equivale a desinstalar: **exporta antes**.

---

## Android

Hay dos opciones. Elige **una** y quédate con ella.

> **La app instalada por APK y la app instalada desde Chrome guardan datos por separado.** No se comparten. Si cambias de una a otra, exporta en la vieja e importa en la nueva.

### Opción 1: APK (recomendada, no necesita servidor ni internet)

**Requisitos:** Android 7 o posterior (recomendado).

**Instalar:**

1. En el teléfono, abre https://github.com/iezappa/nisabitus/releases/latest.
2. En **Assets**, descarga `nisabitus-vX.Y.Z-android.apk`.
3. Abre el archivo descargado. Android pedirá permiso para instalar apps de origen desconocido: toca **Configuración** → activa **Permitir desde esta fuente** → vuelve atrás.
4. Toca **Instalar**. Si Google Play Protect muestra un aviso, elige **Instalar de todas formas** (la app no viene de Play Store).

**Actualizar:** la app te avisa con un aviso **"Hay una versión nueva"** al abrirla con conexión. Toca **Descargar**, haz un respaldo si el aviso lo pide e instala el APK encima. **No desinstales la app anterior**: desinstalar borra los datos. Todas las versiones van firmadas con la misma clave, así que se instalan encima sin problema. Si Android dice que el paquete "entra en conflicto" con el existente, **no desinstales**: exporta tus datos y avisa al desarrollador.

**Actualizaciones automáticas (opcional) con Obtainium:**

1. Instala Obtainium desde https://github.com/ImranR98/Obtainium/releases (o F-Droid).
2. En Obtainium toca **Agregar app** y pega `https://github.com/iezappa/nisabitus`.
3. Toca **Agregar**. Obtainium te notifica cuando hay una versión nueva y la instala encima.

> **Si instalaste la app antes de la primera versión firmada con el keystore de release (ver [`docs/SIGNING.md`](docs/SIGNING.md)):** esa versión usaba otra firma y no se puede actualizar encima. Una sola vez: **Exportar** → desinstalar → instalar el APK nuevo → **Importar**. Si no exportas antes de desinstalar, pierdes tus datos.

**Tus datos:** se guardan dentro de la app. Se pierden si la desinstalas, si tocas **Borrar almacenamiento** en los ajustes de la app o si reseteas el teléfono. Guarda el respaldo en Google Drive u otro dispositivo.

### Opción 2: instalar desde Chrome (PWA)

1. Abre **Chrome** y entra a https://iezappa.github.io/nisabitus/ (o la URL `ts.net` de tu servidor ZimaOS, si la familia usa uno: elige una y no la cambies).
2. Menú **⋮** → **Instalar app** (o **Agregar a la pantalla principal** → **Instalar**).
3. Abre la app desde su ícono y usa siempre la misma dirección.

Funciona sin conexión después de abrirla una vez con internet.

**Actualizar:** al abrir la app con conexión aparece **"Hay una versión nueva"**: toca **Actualizar** y la app se recarga.

**Tus datos:** se guardan en Chrome para esa dirección. Se pierden si desinstalas la app, borras los datos de Chrome o del sitio, o reseteas el teléfono.

---

## Actualizaciones

La app revisa si hay una versión nueva al abrirse con conexión (en computadoras y Android, como mucho cada 6 horas). Sin conexión no pasa nada: sigue funcionando igual (en la versión web, después de haberla abierto una vez con internet).

| Dispositivo | Cómo te enteras | Cómo actualizas |
|---|---|---|
| iPhone y iPad | Aviso "Hay una versión nueva" | Toca **Actualizar**. Si no aparece, cierra la app por completo (deslizar hacia arriba) y ábrela otra vez. |
| Android (APK) | Aviso "Hay una versión nueva" | **Descargar** e instalar encima, o automático con Obtainium (ver [Android](#android)). |
| Android (Chrome) y navegador | Aviso "Hay una versión nueva" | Toca **Actualizar**. |
| Windows, Ubuntu, macOS | Aviso "Hay una versión nueva" | Abre la página de la versión; sigue los pasos **Actualizar** de tu sistema. |

- **Si el aviso pide un respaldo**, la versión nueva cambia cómo se guardan los datos: toca **Exportar** y guarda el archivo **antes** de actualizar.
- Después de actualizar, la app muestra **Novedades** con los cambios de la versión.

---

## Privacidad

Nisabitus no tiene cuentas, analítica ni publicidad, y tus datos no salen de tu dispositivo. Para borrarlos: **Ajustes → Tus datos → Borrar todos mis datos**.

- [Política de privacidad](PRIVACY.md)
- [Términos de uso](TERMS.md)
- English: [Privacy policy](PRIVACY.en.md) · [Terms of use](TERMS.en.md)

Contacto: Zeke Zappa Developments (iezappa) — https://github.com/iezappa/nisabitus/issues

---

## Para desarrolladores

Stack y reglas: `STACK-APPS-DINAMICAS.md` (perfil A) del repo Estandarizador. Pendientes y decisiones: [`TODO.md`](TODO.md); publicación: [`docs/RELEASING.md`](docs/RELEASING.md). Proyecto Flutter en `apps/client`.

```bash
cd apps/client
flutter pub get
dart run build_runner build      # código generado de Drift
flutter test
flutter run -d chrome            # o linux / windows / macos / un dispositivo Android
```

Probar la imagen web localmente:

```bash
docker build -f deploy/Dockerfile -t nisabitus .
docker run --rm -p 8080:8080 nisabitus    # http://localhost:8080
```

Publicar una versión (Releases con Linux, Windows, macOS y web, e imagen `ghcr.io/iezappa/nisabitus`; GitHub Pages se publica en cada push a `main` con `deploy-pages.yml`):

```bash
# La versión de pubspec.yaml (x.y.z+build) y web/update.json deben coincidir con el tag
git tag vX.Y.Z && git push origin vX.Y.Z
```

El CI no compila el APK: tras crear la release, el mantenedor lo firma en local con el keystore de release y lo sube con `tool/release_apk.sh vX.Y.Z` (ejecutado desde `apps/client`). El keystore no está en GitHub. Huella SHA-256 esperada del certificado: `la registrada en [`docs/SIGNING.md`](docs/SIGNING.md) (pendiente hasta que se genere el keystore)` (comprobar con `apksigner verify --print-certs`).

La versión web trae su propio service worker (`web/sw.js`, registrado en `web/flutter_bootstrap.js`); el CI y el Dockerfile ejecutan `tool/generate_sw.sh` tras `flutter build web`. Si una release rompe el service worker, publica el kill switch (`web/sw-killswitch.js`, instrucciones dentro).

Si la versión cambia el esquema de Drift, sube `schemaVersion`, agrega el test de migración y marca `"schemaChange": true` en `web/update.json`: el aviso de actualización pedirá un export antes de actualizar.
