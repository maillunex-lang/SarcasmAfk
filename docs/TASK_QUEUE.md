# TASK_QUEUE.md — Очерёдность задач

> Канон очереди.  
> **Statuses (REPO-REORG-001):** `NOT_STARTED` · `IN_PROGRESS` · `PARTIAL` · `IMPLEMENTED_UNVERIFIED` · `BLOCKED` · `DONE_VERIFIED` · `DEPRECATED`  
> Legacy rows may still say `DONE`/`TODO`/`DOING` — treat `DONE` as `DONE_VERIFIED` only when STATUS evidence exists; otherwise `IMPLEMENTED_UNVERIFIED`.  
> Owner approves priority changes. Agents do not skip `PX` / `BLOCKED`.

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
| T-031 | P1 | **DONE** | Blender→atlas pipeline scripts in repo | `tools/blender_pipeline` + smoke | T-030 |
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
| T-123 | P0 | **DONE** | Persist/reconnect session resume | token save + resume_session | T-087 |
| T-110 | P1 | **DONE** | Debug APK toolchain + build script | `build_debug_apk.sh` → `build/*.apk` | T-100 |
| T-124 | P1 | **DONE** | CH01 vertical polish (L01/battle/dialog) | hub steps + CH02 gates | T-055 |
| T-114 | P1 | **DONE** | Release defaults live (no silent mock); debug toggle | D-NET-05 + integration_live_slice | T-110 |
| T-125 | P1 | **DONE** | CH01 Android vertical slice APK | home→map→L01→dialog→party→battle→ult→reward→save | T-124 |
| T-130 | P1 | **DONE** | CH01 gameplay polish (ULT reachable, pause, reward UI, Home continue, AFK honesty) | battle/home/afk + B01 balance + smoke | T-125 |
| T-132 | P1 | **DONE** | CH01 acceptance test report + owner Q answers; debug APK; live ULT auto_cast fix; party portraits | `docs/reports/CH01_ACCEPTANCE_TEST_2026-11-19.md` | T-130 |
| T-133 | P1 | **DONE** | Balance pass-2: B02+ HP floor ~3200 so ULT reachable | `ch01_battles.json` + smoke B02 | T-132 |
| T-134 | P2 | **DONE** | Heroes/Inventory/AFK/Gacha UX polish (draft art OK) | heroes/inventory/afk/gacha screens | T-132 |
| T-131 | P2 | **BLOCKED** | H01 Kaeron grip + Stage E atlases | owner local Blender grip; then Stage D confirm | owner |
| T-126 | P1 | **BLOCKED** | Release APK signed | debug-only until owner keystore (Q1) | T-125 |
| T-127 | P1 | **BLOCKED** | Owner art-approve H01/H02/H03/E01 | drafts only; no new H01 model | T-125 |
| T-128 | P1 | **BLOCKED** | CH01 accepted (owner sign-off) | report ready; waiting device/review | T-132 |
| T-129 | P1 | **BLOCKED** | Production/live API URL for devices | keep `127.0.0.1:8080/v1`; need owner URL | T-114 |
| T-140 | P1 | **DONE** | Online systems audit + D-SCOPE-03 unlock | `ONLINE_SYSTEMS_AUDIT.md` + DECISIONS | owner brief |
| T-141 | P1 | **DONE** | 36-hero Draft catalog + progression config | `roster_release36.json` + `progression_draft.json` | T-140 |
| T-142 | P1 | **DONE** | DB migration 003 + hero instances / economy hooks | `migrations/003_online_foundation.sql` | T-141 |
| T-143 | P1 | **DONE** | Server progression + chat/guild/shop/VIP APIs | `store/*` + `httpapi/online.go` | T-142 |
| T-144 | P2 | **DONE** | Client screens: hero detail / chat / shop / VIP / guild live | scenes + ApiClient | T-143 |
| T-145 | P3 | **DONE** | Chat WebSocket + DM channel + REST | `/v1/ws/chat` + dm: pair | T-144 |
| T-146 | P4 | **DONE** | Guild roles/announce/chat channel | set_role, announce, guild: chat | T-144 |
| T-147 | P5 | **DONE** | Gacha rates/pity/history (paid OFF) | D-GACHA-01 + SummonBanner | T-144 |
| T-148 | P6 | **DONE** | TEST_PURCHASE shop + limits + history keys | D-SHOP-01 | owner prices later |
| T-149 | P7 | **DONE** | VIP 0–10 + daily claim | D-VIP-01 | owner balance later |
| T-150 | P2 | **DONE** | H13–H36 Draft lore + GameBrain roadmap doc | roster v4 + LUNEX_GAMEBRAIN.md | D-SCOPE-04 |
| T-151 | P3 | **DONE** | Chat moderation admin + mute/delete/reports | `/v1/admin/chat/*` | T-145 |
| T-152 | P4 | **DONE** | Guild quests/vault/member board (+ war/boss hooks empty) | donate + quests + migration 005 | T-146 |
| T-154 | P3 | **DONE** | Persist chat hub to Postgres (`PostgresChat`) | migration 006 + main wire | T-151 |
| T-155 | P1 | **DONE** | UI TEMP art: home/shop/VIP + H13–H36 portraits/fulls + AssetPaths | `client/assets` + home/shop/vip screens | owner art request |
| T-156 | P1 | **DONE** | CH01 RPG Expansion A–C: sidequests/POI data + campaign API + POI UI | `CH01_RPG_EXPANSION.md` + migration 007 | owner TZ |
| T-153 | P6 | **NOT_STARTED** | Real payment provider adapter (when approved) | replace TEST_PURCHASE | owner + D-SHOP-01 |
| T-112 | P3 | **NOT_STARTED** | Arena/events live | after rules; guilds unlocked by D-SCOPE-03 | T-146 |
| T-090 | PX | **BLOCKED** | Детализация глав 02–12 (не открывать игрокам) | D-SCOPE-02 | Явное разрешение |
| T-091 | PX | **BLOCKED** | Массовая генерация **финального** арта / Stage E | D-ART-06 | Явное разрешение |
| T-092 | PX | **BLOCKED** | Rename repo / package ID | — | Явное разрешение |
| T-157 | P1 | **DONE_VERIFIED** | CH01 Expansion E: full E2E + debug APK + owner report | `smoke_ch01_expansion.gd` + `smoke_ch01_expansion_live.sh` + `docs/reports/CH01_EXPANSION_E2E_2026-11-19.md` + debug APK | T-156 |
| T-158 | P1 | **DONE_VERIFIED** | Visual Overhaul 001 Stage F: Theme.tres, H13–H36 busts, gallery, anims, debug APK | `bashlegends_theme.tres` + `visual_gallery/` + `smoke_visual_*` + debug APK | VO-001 |
| T-159 | P0 | **DONE_VERIFIED** | CITY-HUB-001: Stage 0 approved → Ufa interactive city hub vertical slice | `CITY_HUB_001.md` + `home.gd` city + `ufa_buildings.json` + TEMP layers + `smoke_city_hub.gd` | D-UI-CITY-01 |
| T-160 | P0 | **DONE_VERIFIED** | REPO-REORG-001 backup+audit+AI context | reports + AGENTS/STATUS/router; PR #27 | D-REORG-01 |
| T-161 | P1 | **DONE_VERIFIED** | REPO-REORG validators + CI path/link checks | `check_doc_links/ai_docs/content_refs` in `ci_validate.sh` | T-160 |
| T-162 | P1 | **DEPRECATED** | REPO-REORG tracked deletes | No safe tracked deletes; see `REPO_REORG_CLEANUP_DECISIONS.md` | T-160 |

## Правила исполнения

1. Take highest available P among `NOT_STARTED`/`IN_PROGRESS` (P0→P1; P2 parallel if non-conflicting).
2. On start: set `IN_PROGRESS` here + refresh `STATUS.md` NOW.
3. On finish: `DONE_VERIFIED` only with paths + tests + commit/PR; else `PARTIAL` / `IMPLEMENTED_UNVERIFIED`. Log in `ROAD.md` §8.
4. `PX` / owner blockers: require written owner decision + `DECISIONS.md`.
5. New blocker → `BLOCKED` + STATUS row.

## Следующий конкретный шаг

1. **Review/merge** T-159 CITY-HUB-001 PR (Ufa interactive city hub).  
2. Owner: device accept **T-128** / live URL **T-129** when ready.  
3. Still blocked: T-153 payments, T-112 arena/events, T-090 CH02, T-131 Stage E, T-126 keystore. Next polish: final city iso art (still TEMP).
