# TASK_QUEUE.md — Очерёдность задач

> Канон очереди. Статусы: `TODO` · `DOING` · `BLOCKED` · `DONE` · `CANCELLED`  
> Владелец проекта утверждает смену приоритета. ИИ не перескакивает через запреты.

## Легенда приоритета

| P | Значение |
|---|---|
| P0 | Сейчас / разблокирует всё |
| P1 | Следующий обязательный блок |
| P2 | Параллельно или сразу после P1 |
| P3 | После V0 / по ROAD |
| PX | Запрещено до явного разрешения |

## Очередь (исполнять сверху вниз)

| ID | P | Статус | Задача | Спека / выход | Зависит от |
|---|---|---|---|---|---|
| T-001 | P0 | **DONE** | Каркас GDD + ROAD в репо | `GDD.md`, `ROAD.md` | — |
| T-002 | P0 | **DONE** | Каталог героев + CH01 сценарий (проект) | `HEROES.md`, `CAMPAIGN_LOCATIONS.md` | T-001 |
| T-003 | P0 | **DONE** | Визуальный пакет документов | ART/DESIGN/LOCATION/CHARACTER/PIPELINE/VISUAL_ROADMAP | T-001 |
| T-004 | P0 | **DONE** | Утверждение решений V0 | название / портреты / Blender→atlas | T-003 |
| T-005 | P0 | **DONE** | План реализации V0 | `V0_IMPLEMENTATION_PLAN.md` | T-004 |
| T-006 | P0 | **DONE** | Merge документов в `main` | PR #1 merged | T-005 |
| T-007 | P0 | **DONE** | Дефрагментация docs для ИИ | `AGENTS.md`, `STATUS`, `INDEX`, `TASK_QUEUE`, `DECISIONS` | T-006 |
| T-010 | P1 | **DONE** | **V0-A:** Godot 4 skeleton 9:16 | `client/` Splash/Home/L01/Dialog/Battle + smoke | T-007 |
| T-020 | P2 | **DONE** | Phase 0: API/data contracts + audit репо | `docs/PHASE0_SPEC.md` | T-001 |
| T-021 | P2 | **DONE** | Минимальный CI (JSON + Godot smoke) | `.github/workflows/ci.yml` | T-010 |
| T-030 | P1 | **DONE** | **V0-B:** точечный арт только среза | `client/assets/` поэлементно + wire-in | T-010 |
| T-031 | P1 | **BLOCKED** | Blender→atlas pipeline scripts in repo | scripts ≠ final art; нет Blender в CI | T-030 |
| T-040 | P1 | **DONE** | **V0-C:** playable demo-path | autofight B01 + GameState + rewards | T-030 |
| T-050 | P1 | **DONE** | **V0-D:** review + стоп-линия | `docs/V0_REVIEW.md` | T-040 |
| T-055 | P1 | **DONE** | **CH01 embed:** квесты/локации/бои/диалоги в клиент | `client/data/` + CampaignCatalog + campaign UI + `smoke_ch01.gd` | T-050 |
| T-056 | P1 | **DONE** | Тонкий `ApiClient` + `USE_MOCK` | `client/scripts/net/api_client.gd` + `smoke_api.gd` | T-020, T-055 |
| T-060 | P1 | **DONE** | Уникальные локации L02–L10 слои + арены | `locations/L02–L10` + `ARENA-L02–L10` | T-050 |
| T-061 | P1 | **DONE** | Art-fill: иконки/BG/H04–H12/враги-архетипы | `client/assets/` + AssetPaths wire | T-077 |
| T-070 | P1 | **DONE** | Клиент MVP экраны (ROAD Фаза 1) | 12 экранов на моках | T-050, T-020 |
| T-071 | P1 | **DONE** | Ф1.1 Оболочка / nav / карта | HubChrome + Map + More | T-070 |
| T-072 | P1 | **DONE** | Ф1.2 Коллекция 12 героев | `roster_mvp.json` + Heroes | T-071 |
| T-073 | P1 | **DONE** | Ф1.3 Бой 5 героев / 2 линии | Party + battle rows | T-072 |
| T-074 | P1 | **DONE** | Ф1.4 AFK / экспедиции / события | AFK+Expedition+Events | T-073 |
| T-075 | P1 | **DONE** | Ф1.5 RPG / экип / экономика / гача | Inventory+Gacha | T-074 |
| T-076 | P1 | **DONE** | Ф1.6 Гильдия / арена / города | Guild+Arena+cities JSON | T-075 |
| T-077 | P1 | **DONE** | Ф1.7 E2E smoke + аудит | `smoke_mvp.gd` + PHASE1_AUDIT | T-076 |
| T-080 | P1 | **DONE** | Сервер Go Phase2 stub (пакет) | `server/` + CI go-api | T-070 |
| T-081 | P1 | **DONE** | Ф2.1 Go API + anonymous auth + progress | `server/cmd/api` + store | T-080 |
| T-082 | P1 | **DONE** | Ф2.2 Rewards/AFK/gacha idempotent | `/rewards/claim` `/afk` `/gacha` | T-081 |
| T-083 | P1 | **DONE** | Ф2.3 Battle start/finish seed stub | `/battles/{id}/start|finish` | T-082 |
| T-084 | P1 | **DONE** | Ф2.4 Guild/arena/events stubs + CI | `/guild` `/arena` `/events` | T-083 |
| T-085 | P1 | **DONE** | Postgres + Redis + soft battle verify | `store/postgres` + `battleverify` + compose | T-089 |
| T-086 | P1 | **DONE** | ApiClient live HTTP (`use_mock=false`) | `api_client.gd` HTTPClient | T-084 |
| T-087 | P1 | **DONE** | File persist sessions/accounts | `store` JSON persist reload | T-084 |
| T-088 | P1 | **DONE** | Battle finish session gate | `NO_ACTIVE_BATTLE` | T-083 |
| T-089 | P1 | **DONE** | Integration smoke curl+Godot live | `scripts/smoke_live_api.sh` | T-086 |
| T-093 | P1 | **DONE** | Admin health/metrics/readyz | `/readyz` `/v1/admin/metrics` | T-085 |
| T-094 | P1 | **DONE** | Request logging + counters | httpapi middleware | T-093 |
| T-095 | P1 | **DONE** | Client UI live API toggle | More + GameState.set_live_api | T-086 |
| T-096 | P1 | **DONE** | Postgres backup script | `scripts/backup_db.sh` | T-085 |
| T-097 | P1 | **DONE** | Server ATB tick battle sim | `battleverify/sim.go` | T-085 |
| T-098 | P1 | **DONE** | Finish uses tick-sim truth | `/battles/{id}/finish` | T-097 |
| T-099 | P1 | **DONE** | Concurrent load smoke | `scripts/load_smoke.sh` | T-089 |
| T-100 | P2 | **DONE** | Android export preset stub | `export_presets.cfg.example` | T-070 |
| T-101 | P1 | **DONE** | Ultimates in server ATB sim | `battleverify` castUltimate | T-097 |
| T-102 | P1 | **DONE** | Client battle uses server seed | `BattleEngine.setup(rng_seed)` | T-098 |
| T-103 | P1 | **DONE** | Phase 2 audit + roadmap refresh | `PHASE2_AUDIT.md` | T-100 |
| T-111 | P0 | **DONE** | Admin RBAC lock + audit | `ADMIN_API_KEY` roles admin/viewer | T-093 |
| T-113 | P0 | **DONE** | Battle replay + commands + auth finish | seed/balance/party/cmds | T-101 |
| T-120 | P0 | **DONE** | Live probe; no silent mock fallback | `probe_live` + More UX | T-095 |
| T-121 | P0 | **DONE** | Live rewards only from server finish | `complete_battle(server_finish)` | T-113 |
| T-122 | P0 | **DONE** | Mark guild/arena/events unavailable | D-SCOPE-01 UI | T-084 |
| T-123 | P0 | **TODO** | Persist/reconnect session resume | token restore + progress sync | T-087 |
| T-110 | P1 | **TODO** | Debug APK + SDK/templates/keystore check | no new release key if exists | T-100 |
| T-124 | P1 | **TODO** | CH01 vertical polish (L01/battle/dialog) | playable slice | T-055 |
| T-112 | P3 | **TODO** | Guild/arena/events live | after CH01 vertical | T-122 |
| T-114 | P3 | **TODO** | Phase 3 acceptance: no-mock release path | ROAD Фаза 3 | T-110 |
| T-090 | PX | **BLOCKED** | Детализация глав 02–12 (не открывать игрокам) | D-SCOPE-02 | Явное разрешение |
| T-091 | PX | **BLOCKED** | Массовая генерация ассетов вне V0 | — | Явное разрешение |
| T-092 | PX | **BLOCKED** | Rename repo / package ID | — | Явное разрешение |

## Правила исполнения

1. Брать только верхний `TODO` с наивысшим доступным P (P0→P1; P2 можно параллельно, если не конфликтует).
2. Перед стартом: статус → `DOING` в этой таблице + обновить `STATUS.md` NOW.
3. По завершении: `DONE`, доказательства (пути файлов / коммит), запись в `ROAD.md` §8.
4. `PX` не трогать без письменного решения владельца в чате/issue + запись в `DECISIONS.md`.
5. Если задача выяснила новый блокер — статус `BLOCKED` и строка в `STATUS.md`.

## Следующий конкретный шаг после T-121

`T-123` session resume · затем `T-110` debug APK · `T-031` Blender pipeline scripts · `T-124` CH01 polish.
