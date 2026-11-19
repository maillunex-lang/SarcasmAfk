# BashLegends API (Phase 2 stub)

Go HTTP API per `docs/PHASE0_SPEC.md`. In-memory account store (optional JSON persist).  
PostgreSQL + Redis — next hardening step; not required to run this stub.

## Run

```bash
cd server
go test ./...
go run ./cmd/api -addr :8080 -content ../client/data
```

## Endpoints

| Method | Path | Auth |
|---|---|---|
| GET | `/healthz` | no |
| POST | `/v1/auth/anonymous` | no |
| GET | `/v1/me/progress` | Bearer |
| PUT | `/v1/me/party` | Bearer |
| GET | `/v1/content/heroes` | no |
| GET | `/v1/content/battles/{id}` | no |
| GET | `/v1/content/dialogues/{id}` | no |
| POST | `/v1/battles/{id}/start` | Bearer |
| POST | `/v1/battles/{id}/finish` | Bearer |
| POST | `/v1/rewards/claim` | Bearer |
| POST | `/v1/afk/claim` | Bearer |
| POST | `/v1/gacha/summon` | Bearer |
| GET | `/v1/guild` | Bearer |
| GET | `/v1/arena` | Bearer |
| GET | `/v1/events` | no |

Client Godot still defaults `ApiClient.USE_MOCK=true`; set false and point `BASE_URL` when integrating.
