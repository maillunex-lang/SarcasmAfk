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
| T-060 | P3 | **TODO** | Расширение арта CH01 (L02–L10) | по LOCATION/CAMPAIGN | T-050 |
| T-070 | P3 | **TODO** | Клиент MVP экраны (ROAD Фаза 1) | 12 экранов на моках | T-050, T-020 |
| T-080 | P3 | **TODO** | Сервер Go + замена моков (Фаза 2) | TECH-001 | T-070 |
| T-090 | PX | **BLOCKED** | Детализация глав 02–12 | полные квесты/бои | Явное разрешение владельца |
| T-091 | PX | **BLOCKED** | Массовая генерация ассетов вне V0 | — | Явное разрешение |
| T-092 | PX | **BLOCKED** | Rename repo / package ID | — | Явное разрешение |

## Правила исполнения

1. Брать только верхний `TODO` с наивысшим доступным P (P0→P1; P2 можно параллельно, если не конфликтует).
2. Перед стартом: статус → `DOING` в этой таблице + обновить `STATUS.md` NOW.
3. По завершении: `DONE`, доказательства (пути файлов / коммит), запись в `ROAD.md` §8.
4. `PX` не трогать без письменного решения владельца в чате/issue + запись в `DECISIONS.md`.
5. Если задача выяснила новый блокер — статус `BLOCKED` и строка в `STATUS.md`.

## Следующий конкретный шаг после T-050 / T-020 / T-021

Расширять **CH01** (B02+) на моках **или** добавить Godot `ApiClient` (USE_MOCK). **T-031** — при Blender. Владельцу: визуальный sign-off по `V0_REVIEW.md`.
