# Publicar Nisabitus en ZimaOS

> Guía para servir la versión web/PWA de Nisabitus desde un servidor ZimaOS doméstico, para uso familiar.

**Antes de empezar, lo más importante:** el servidor **solo sirve la app**. Los datos de cada persona se guardan en **su propio navegador o dispositivo**, no en ZimaOS. Dos familiares no comparten datos, y si alguien borra la app o los datos del sitio, pierde lo que no haya exportado. El backup es el **export JSON** desde Ajustes → Tus datos.

## Requisitos

- Una release publicada (tag `v*`): el workflow `release` sube la imagen `ghcr.io/iezappa/nisabitus`.
- ZimaOS con acceso a la interfaz web y a internet.

## 1. Publicar la imagen

```bash
git tag v1.0.0
git push origin v1.0.0
```

El workflow `release` construye y sube `ghcr.io/iezappa/nisabitus:1.0.0` y `:latest` para `amd64` y `arm64`.

La primera vez, haz **público** el paquete: GitHub → tu perfil u organización → *Packages* → el paquete → *Package settings* → *Change visibility* → *Public*. Si queda privado, ZimaOS no podrá descargarlo sin credenciales.

## 2. Instalar en ZimaOS

1. Descarga `deploy/docker-compose.yml`. Ya viene completo; solo cambia el puerto `8081` (dos lugares) si está ocupado en tu servidor.
2. En ZimaOS abre **App Store** → botón **"+"** (esquina superior) → **Install a customized app**.
3. Usa **Import** y pega o sube el `docker-compose.yml`. Revisa que la imagen y el puerto sean los esperados.
4. **Install**. Al terminar aparece el ícono en el escritorio de ZimaOS.
5. Comprueba que carga en `http://<ip-de-zimaos>:8081`. **Esta URL es solo para verificar**, no para que la familia la use (ver paso 3).

> Los nombres de menú pueden variar entre versiones de ZimaOS. Si no encuentras "Install a customized app", busca la opción de instalación personalizada o de importar docker-compose en la App Store.

## 3. HTTPS para la familia con Tailscale

Instalar la PWA, el service worker y el almacenamiento OPFS exigen HTTPS. `http://IP:puerto` carga, pero no es instalable y puede perder funciones.

1. Instala **Tailscale** desde la App Store de ZimaOS e inicia sesión con tu cuenta de Tailscale.
2. En la consola de administración de Tailscale habilita **MagicDNS** y **HTTPS Certificates**.
3. En una terminal de ZimaOS (SSH), expón la app:

   ```bash
   tailscale serve --bg http://127.0.0.1:8081
   tailscale serve status
   ```

   Si Tailscale corre como contenedor, ejecuta el comando dentro de él (`docker exec -it <contenedor-tailscale> tailscale serve --bg http://<ip-de-zimaos>:8081`), porque `127.0.0.1` dentro del contenedor no es el host.
4. La app queda en `https://<nombre-del-servidor>.<tu-tailnet>.ts.net/`.
5. Cada familiar instala Tailscale en su dispositivo y se une a tu tailnet (invitación o compartir el nodo).

**Usa siempre la URL `ts.net`, también dentro de casa.** El almacenamiento del navegador es por origen: los datos guardados entrando por la IP local no aparecen al entrar por `ts.net`, y viceversa. Una sola URL para todo.

## 4. Instalar la app en cada dispositivo

| Dispositivo | Cómo |
|---|---|
| **iPhone / iPad** | Abrir la URL `ts.net` en **Safari** → Compartir → **Agregar a inicio**. Usar siempre el ícono de inicio, no la pestaña de Safari: así el almacenamiento no se borra por inactividad de Safari. |
| **Android** | Chrome → menú → **Instalar app**. Alternativa: descargar el APK de GitHub Releases (funciona sin servidor ni Tailscale). |
| **Windows / macOS / Linux** | Chrome o Edge → ícono de instalar en la barra de direcciones. Alternativa: binario de GitHub Releases. |

Tras instalar, abrir la app una vez con conexión y comprobar en Ajustes que el export JSON funciona.

## 5. Datos y backups

- Cada persona exporta su JSON periódicamente (la app lo recuerda) y lo guarda fuera del navegador: Archivos de iCloud/Drive, o una carpeta compartida de ZimaOS.
- Para pasar a otro dispositivo: exportar en el viejo, importar en el nuevo.
- Reinstalar o actualizar el contenedor **no** afecta los datos: no están en el servidor.

## 6. Actualizar

1. Publica un tag nuevo (`v1.1.0`). El workflow actualiza `:latest`.
2. En ZimaOS, abre los ajustes de la app y usa la opción de actualizar/volver a descargar la imagen, o por SSH:

   ```bash
   docker pull ghcr.io/iezappa/nisabitus:latest
   ```

   y reinicia la app desde la interfaz de ZimaOS para que el contenedor se recree con la imagen nueva.
3. Al abrir la app con conexión, el service worker propio (`sw.js`) descarga la versión nueva en segundo plano y la app muestra **"Hay una versión nueva"**. Al tocar **Actualizar**, la app se recarga con la versión nueva y borra la caché anterior.

Si la versión nueva cambia el esquema de Drift, la migración corre en cada dispositivo al abrir la app. Pide a la familia un export JSON **antes** de publicar releases con cambios de esquema.
