# Local-first Flutter web app served by nginx.
#
# Build context: repository root (the folder that contains apps/client and deploy/).
#   docker build -f deploy/Dockerfile -t nisabitus .
#
# Multi-arch (ZimaBoard/ZimaBlade are x86_64; some home servers are ARM):
#   docker buildx build -f deploy/Dockerfile \
#     --platform linux/amd64,linux/arm64 \
#     -t ghcr.io/iezappa/nisabitus:latest --push .
#
# The Flutter build output (HTML/JS/WASM) is architecture-independent, so the
# build stage always runs on the builder's native platform ($BUILDPLATFORM).
# Only the tiny nginx stage is resolved per target platform: no QEMU emulation
# of the Flutter SDK is needed.

# Pinned to the toolchain CI tests with (release.yml passes the same tag, so
# this default only applies to a local `docker build`).
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:3.47.1

# ---------- Stage 1: build Flutter web ----------
FROM --platform=$BUILDPLATFORM ${FLUTTER_IMAGE} AS build

# Path of the Flutter project inside the repository.
ARG APP_DIR=apps/client
# The container serves the app at the root of its own origin.
ARG BASE_HREF=/

WORKDIR /src
COPY ${APP_DIR}/pubspec.yaml ${APP_DIR}/pubspec.lock* ./
RUN flutter pub get

COPY ${APP_DIR}/ ./
# --no-web-resources-cdn: bundle CanvasKit/skwasm instead of loading them from
# gstatic.com. Required because nginx.conf sends
# Cross-Origin-Embedder-Policy: require-corp (see comments there).
RUN flutter build web --release \
      --base-href "${BASE_HREF}" \
      --no-web-resources-cdn

# Drift needs these two files next to index.html (same Drift version).
RUN test -f build/web/sqlite3.wasm && test -f build/web/drift_worker.js \
    || (echo "Missing web/sqlite3.wasm or web/drift_worker.js (see Drift web docs)" && exit 1)

# Own service worker (STACK-APPS-DINAMICAS.md 8.2): inject version + precache
# manifest into build/web/sw.js. Must run after the last file lands in build/web.
RUN sh tool/generate_sw.sh build/web pubspec.yaml

# ---------- Stage 2: serve with nginx (non-root, port 8080) ----------
FROM nginxinc/nginx-unprivileged:stable-alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8080/healthz || exit 1
