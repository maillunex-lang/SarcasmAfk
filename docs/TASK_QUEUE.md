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
| T-031 | P1 | **BLOCKED** | Пилот Blender→atlas на H01 | нет Blender в среде; combat = still sprites | T-030 |
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
| T-090 | PX | **BLOCKED** | Детализация глав 02–12 | полные квесты/бои | Явное разрешение владельца |
| T-091 | PX | **BLOCKED** | Массовая генерация ассетов вне V0 | — | Явное разрешение |
| T-092 | PX | **BLOCKED** | Rename repo / package ID | — | Явное разрешение |

## Правила исполнения

1. Брать только верхний `TODO` с наивысшим доступным P (P0→P1; P2 можно параллельно, если не конфликтует).
2. Перед стартом: статус → `DOING` в этой таблице + обновить `STATUS.md` NOW.
3. По завершении: `DONE`, доказательства (пути файлов / коммит), запись в `ROAD.md` §8.
4. `PX` не трогать без письменного решения владельца в чате/issue + запись в `DECISIONS.md`.
5. Если задача выяснила новый блокер — статус `BLOCKED` и строка в `STATUS.md`.

## Следующий конкретный шаг после T-085

Админка/мониторинг (Фаза 2) **или** UI live-toggle в клиенте **или** полный tick-sim боёв. **T-031** — при Blender.
