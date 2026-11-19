# PHASE2_AUDIT.md — Аудит сервера и замены моков (2026-11-19)

> Факт по репо после T-081…T-102. Не путать stub/`DONE` с релизной готовностью.

## Готово (есть код + тесты)

| Область | Доказательство |
|---|---|
| Go API + anonymous auth | `server/cmd/api`, `go test` |
| Memory / Postgres / Redis stores | `store/memory.go`, `store/postgres.go`, compose |
| Rewards / AFK / gacha idempotent | endpoints + tests |
| Battle start/finish + ATB tick-sim + ultimates auto | `battleverify/sim.go` |
| Live ApiClient + More toggle | `api_client.gd`, `more_screen.gd` |
| Smokes | `smoke_live_api.sh`, `load_smoke.sh`, CI |

## Частично / stub

| Область | Что есть | Чего нет |
|---|---|---|
| Guild / arena / events | GET stubs | CRUD, matchmaking, persistence |
| Admin | `/readyz`, metrics, logs | RBAC, auth на admin, UI |
| Client default | `use_mock=true` | Релизный режим без моков |
| Android | `export_presets.cfg.example` | Signed APK (нет SDK/templates в CI) |
| Battle parity | Seed sync + ATB formulas | Replay `actions_hash`, ручные ульты ≠ auto |
| Content | CH01 JSON | Главы 02–12 (PX) |
| Art | Draft placeholders L02–L10 / H04–H12 | Blender atlases (T-031 BLOCKED) |

## Не начато (Фаза 3+)

- Полный режим без моков end-to-end на устройстве
- Платежи / античит hardening / профилирование Android
- Гильдейские базы, PvP арена live, сезоны
- Массовая генерация ассетов / rename (PX)

## Вопросы владельцу (блокируют «доделать»)

См. итоговый список в ответе агента / `STATUS.md` § Needs owner.
