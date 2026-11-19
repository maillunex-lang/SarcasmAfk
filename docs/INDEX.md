# INDEX.md — Карта документов

> Что читать для какой задачи. Избегать дублирования «истины»: статусы только в `STATUS`/`TASK_QUEUE`.

## 0. Точка входа (всегда сначала)

| Файл | Роль |
|---|---|
| [`../AGENTS.md`](../AGENTS.md) | Обязательный протокол для ИИ |
| [`STATUS.md`](STATUS.md) | Снимок: сделано / не сделано / NOW |
| [`TASK_QUEUE.md`](TASK_QUEUE.md) | Очерёдность задач |
| [`DECISIONS.md`](DECISIONS.md) | Утверждённые решения |
| [`OWNER_CLARIFICATIONS.md`](OWNER_CLARIFICATIONS.md) | Открытые вопросы к владельцу (T-126…T-129) |

## 1. Продукт и процесс

| Файл | Роль | Статус истины |
|---|---|---|
| [`GDD.md`](GDD.md) | Утверждённый каркас решений по системам | Каркас утверждён; детали открыты |
| [`ROAD.md`](ROAD.md) | Дорожная карта, фазы, журнал прогресса | Процесс + журнал; не код |

## 2. Контент

| Файл | Роль | Статус истины |
|---|---|---|
| [`HEROES.md`](HEROES.md) | 12 героев MVP (карточки) | Проект каталога |
| [`CAMPAIGN_LOCATIONS.md`](CAMPAIGN_LOCATIONS.md) | CH01: локации, квесты, диалоги, 30 боёв | Проект сценарного пакета |
| [`EQUIPMENT_SYSTEM.md`](EQUIPMENT_SYSTEM.md) | EQUIPMENT-001 архитектура / API / slots | Draft system |
| [`EQUIPMENT_BALANCE.md`](EQUIPMENT_BALANCE.md) | Upgrade / sets / salvage Draft числа | Draft balance |
| [`EQUIPMENT_CONTENT.md`](EQUIPMENT_CONTENT.md) | Каталог 32, CH01 rewards, TEMP icons | Content pack |
| [`CH01_ENEMY_AUDIT.md`](CH01_ENEMY_AUDIT.md) | Аудит 29 enemy_type / арт-дыры | Audit |
| [`MONSTERS_CH01.md`](MONSTERS_CH01.md) | MONSTERS-CH01-001 статус и блок D-ART-06 | In progress |

## 3. Визуал

| Файл | Роль |
|---|---|
| [`ART_DIRECTION.md`](ART_DIRECTION.md) | Художественная концепция |
| [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) | UI-токены и экраны |
| [`LOCATION_STYLE_GUIDE.md`](LOCATION_STYLE_GUIDE.md) | Локации / арены |
| [`CHARACTER_STYLE_GUIDE.md`](CHARACTER_STYLE_GUIDE.md) | Герои / враги / анимации |
| [`ASSET_PIPELINE.md`](ASSET_PIPELINE.md) | Производство и оптимизация ассетов |
| [`VISUAL_ROADMAP.md`](VISUAL_ROADMAP.md) | Порядок визуальных работ + аудит |

## 4. Исполнение / инженерия

| Файл | Роль |
|---|---|
| [`V0_IMPLEMENTATION_PLAN.md`](V0_IMPLEMENTATION_PLAN.md) | Фазы V0-A…D |
| [`V0_REVIEW.md`](V0_REVIEW.md) | Review + стоп-линия T-050 |
| [`PHASE0_SPEC.md`](PHASE0_SPEC.md) | API/data contracts |
| [`PHASE1_AUDIT.md`](PHASE1_AUDIT.md) | Аудит клиентского MVP |
| [`PHASE2_AUDIT.md`](PHASE2_AUDIT.md) | Аудит сервера / mock-replace |
| [`../client/README.md`](../client/README.md) | Как запустить клиент |
| [`../server/README.md`](../server/README.md) | Go API (memory / Postgres+Redis) |
| [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml) | CI |
| [`../scripts/ci_validate.sh`](../scripts/ci_validate.sh) | Локальный CI |
| [`../docker-compose.yml`](../docker-compose.yml) | Postgres + Redis |
| [`ANDROID_BUILD.md`](ANDROID_BUILD.md) | Debug APK toolchain (T-110) |
| [`../tools/blender_pipeline/README.md`](../tools/blender_pipeline/README.md) | Blender→atlas pipeline (T-031) |

## 5. Код и ассеты

| Путь | Сейчас |
|---|---|
| [`../client/`](../client/) | Godot 4.3: V0 + Phase1 screens + CH01 data (mock default) |
| `client/assets/` | Draft/placeholder art (не Blender atlases) |
| [`../server/`](../server/) | Phase 2 Go API + tick-sim |
| `.github/workflows/` | JSON + Godot smokes + Go API + load |

## 6. Анти-фрагментация (правила)

1. **Не** писать новый «NEXT STEP» в гайдах — только ссылка на `STATUS.md` / `TASK_QUEUE.md`.
2. Журнал работ — в `ROAD.md` §8; дублировать кратко в `STATUS` при смене NOW.
3. Решения владельца — только в `DECISIONS.md` (+ правка профильного гайда).
4. Промпты генерации живут в VIS-гайдах; факт «ассет готов» — только после файла в репо + статус в `TASK_QUEUE`.
5. README — короткий указатель, не второй ROAD.
