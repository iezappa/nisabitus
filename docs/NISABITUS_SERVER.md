# Nisabitus Server edition

Nisabitus has two deployment profiles:

- **Local-first PWA**: static Flutter Web served by nginx. Data lives in each browser/device.
- **Server edition**: Flutter Web plus a Dart API. Data is persisted on the server per logged-in user.

This document tracks the server edition plan for ZimaOS/CasaOS.

## Stack

- Existing Flutter Web frontend remains local-first in the first slice.
- Dart `shelf` API for the server-backed edition.
- SQLite database stored in a Docker volume.
- Local username/password login.
- Per-user backup document persistence.

## First implementation slice

The first slice intentionally keeps the server-side data model small:

- `users`: local accounts.
- `sessions`: bearer tokens.
- `user_documents`: one Nisabitus backup JSON document per user.

API:

- `GET /healthz`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/me`
- `GET /api/backup/export`
- `POST /api/backup/import`

Import/export keeps the familiar backup workflow, but the document is stored on
ZimaOS for the authenticated user instead of only inside one browser profile.

## Docker

The first Docker target packages the API and SQLite persistence. It serves a
small status page until the Flutter client gains server-mode login and remote
repositories.

Server image build target:

```bash
docker build -f deploy/server.Dockerfile -t nisabitus-server .
```

Compose example:

```bash
docker compose -f deploy/docker-compose.server.yml up -d
```

On first start set:

- `NISABITUS_ADMIN_USER`
- `NISABITUS_ADMIN_PASSWORD`

Persistent data lives under `/app/data`, mounted by the compose file to `./data`.

## Next slices

1. Add client-side server mode detection (`/config.json` or compile-time flag).
2. Add a login screen in the Flutter app for server mode.
3. Add a remote backup repository that talks to `/api/backup/*`.
4. Replace the single backup-document persistence with normalized per-user tables
   where useful, while preserving export/import compatibility.
5. Add user management and password rotation.
