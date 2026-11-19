# BashLegends API (Phase 2)

Go HTTP API per `docs/PHASE0_SPEC.md`.

Backends:
- **memory** (+ optional JSON persist) — default, no deps
- **Postgres + optional Redis** — set `DATABASE_URL` / `REDIS_ADDR` (T-085)

## Run (memory)

```bash
cd server
go test ./...
go run ./cmd/api -addr :8080 -content ../client/data
# or: ../scripts/run_api.sh
```

## Run (Postgres + Redis)

```bash
# docker compose -f ../docker-compose.yml up -d   # if Docker available
export DATABASE_URL='postgres://bashlegends:bashlegends@127.0.0.1:5432/bashlegends?sslmode=disable'
export REDIS_ADDR=127.0.0.1:6379
../scripts/run_api.sh
```

Migrations: `migrations/*.sql` (directory auto-applied with `-migrate`). Set `ADMIN_API_KEY` to unlock `/v1/admin/*`.

## Endpoints

| Method | Path | Auth |
|---|---|---|
| GET | `/healthz` | no |
| GET | `/readyz` | no |
| GET | `/v1/admin/metrics` | `ADMIN_API_KEY` (viewer+) |
| GET | `/v1/admin/audit` | `ADMIN_API_KEY` (admin) |
| POST | `/v1/battles/{id}/command` | Bearer (ultimate) |
| POST | `/v1/auth/anonymous` | no |
| GET | `/v1/me/progress` | Bearer |
| PUT | `/v1/me/party` | Bearer |
| GET | `/v1/content/heroes` | no |
| GET | `/v1/content/battles/{id}` | no |
| GET | `/v1/content/dialogues/{id}` | no |
| POST | `/v1/battles/{id}/start` | Bearer |
| POST | `/v1/battles/{id}/finish` | Bearer (soft verify) |
| POST | `/v1/rewards/claim` | Bearer |
| POST | `/v1/afk/claim` | Bearer |
| POST | `/v1/gacha/summon` | Bearer |
| GET | `/v1/guild` | Bearer |
| GET | `/v1/arena` | Bearer |
| GET | `/v1/events` | no |

Battle finish: requires active session, `duration_ms >= 300`, then **ATB tick-sim with ultimate auto-cast** (`RESULT_MISMATCH` / `BATTLE_TOO_FAST`).  
Load smoke: `bash scripts/load_smoke.sh`. Audit: `docs/PHASE2_AUDIT.md`.

Client Godot defaults `ApiClient.use_mock=true`. Live:

```gdscript
api.configure_live("http://127.0.0.1:8080/v1")
api.auth_anonymous()
```

Integration: `bash scripts/smoke_live_api.sh`
