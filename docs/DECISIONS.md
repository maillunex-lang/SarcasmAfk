# DECISIONS.md — Утверждённые решения (не менять молча)

> Журнал зафиксированных выборов. Новый ИИ **не** «улучшает» их без владельца.  
> Коды вариантов из GDD сохраняются как в `GDD.md`.

## D-META — Процесс

| ID | Решение | Дата |
|---|---|---|
| D-META-01 | Client-first затем сервер (`ROAD-002 A`) | 2026-11-19 |
| D-META-02 | Тесты + аудит + обновление ROAD (`ROAD-003 D`) | 2026-11-19 |
| D-META-03 | Расширенный MVP (`ROAD-001 C`) | 2026-11-19 |
| D-META-04 | Repo `SarcasmAfk` и package ID не переименовывать без отдельного подтверждения | 2026-11-19 |
| D-META-05 | Рабочая ветка после PR #1: `cursor/phase0-design-docs-beaf`; изменения сливать в `main` | 2026-11-19 |
| D-META-06 | Канон состояния для ИИ: `AGENTS.md` → `STATUS` → `TASK_QUEUE` → `DECISIONS` → `INDEX` | 2026-11-19 |
| D-META-07 | Phase 2 стартует с Go in-memory/file stub (`server/`); Postgres+Redis — отдельный T-085 | 2026-11-19 |
| D-META-08 | Приоритеты после 2026-11-19: P0 безопасность/авторитетный бой/replay/live API; P1 APK+CH01 вертикаль+арт; P2 админка/Blender pipeline/CH01 расширение; P3 guild/arena/events/CH02+ | 2026-11-19 |
| D-META-09 | Не удалять существующие данные и не менять production-конфиг без отдельного согласования | 2026-11-19 |
| D-META-10 | Канон чтения ИИ (REPO-REORG-001): `AGENTS` → `PROJECT_CONTEXT` → `STATUS` → `TASK_QUEUE` → `AI_TASK_ROUTER` → профильная спека → код | 2026-11-19 |
| D-REORG-01 | Удаления/архив только после пофайлового OK владельца по `docs/reports/REPO_REORG_DELETE_CANDIDATES.md`; backup branch/tag обязательны до правок | 2026-11-19 |

## D-COMBAT — Бой / сервер (утверждено 2026-11-19)

| ID | Решение |
|---|---|
| D-COMBAT-01 | Сервер авторитетен для боевой симуляции |
| D-COMBAT-02 | Auto-cast ультимейтов на сервере по умолчанию |
| D-COMBAT-03 | Ручные ультимейты — валидируемые команды игрока |
| D-COMBAT-04 | Детерминированная симуляция + replay: seed, balance_version, составы, команды |
| D-COMBAT-05 | Клиент не назначает победу и награды самостоятельно (в live) |

## D-NET — Сеть / окружения

| ID | Решение |
|---|---|
| D-NET-01 | Mock остаётся для разработки и автономных тестов |
| D-NET-02 | Тестовый APK: live API по умолчанию только после успешного probe (health+auth) |
| D-NET-03 | Явный переключатель окружения для разработчика |
| D-NET-04 | При ошибке live **не** переключаться молча на mock |
| D-NET-05 | **T-114:** release-сборки: `use_mock=false` по умолчанию после прохождения integration (auth/battle/rewards/save/resume); debug: явный mock/live |
| D-NET-06 | P3 guild/arena/events live — только после CH01 accepted; до этого stubs + контракты |
| D-NET-07 | Live URL: использовать существующий `client_config` / env; не выдумывать адрес и не уходить в offline-only без согласования (2026-11-19) |

## D-ART — Арт

| ID | Решение |
|---|---|
| D-ART-01 | Оригинальные игровые ассеты; пайплайн Blender→animation→transparent 2D atlases→Godot 4 |
| D-ART-02 | Временные заглушки допустимы в разработке, не считать финальным артом |
| D-ART-03 | T-031: воспроизводимый Blender-пайплайн в репо (скрипты ≠ готовые ассеты) |
| D-ART-04 | Sample-атлас (`sample_unit`) — **только** для техотладки пайплайна, не финальный игровой ассет (2026-11-19) |
| D-ART-05 | H01 Каэрон / H02 Вейриса / H03 Эльдарион и враги CH01: уникальный дизайн по `HEROES.md`, `CHARACTER_STYLE_GUIDE.md`, `ART_DIRECTION.md` |
| D-ART-06 | Не начинать CH02 и массовую генерацию ассетов до приёмки CH01 |
| D-ART-07 | H01–H03/E01 combat = **черновики** до явного art-approve; H01 модель = Meshy GLB владельца (не генерировать заново) (2026-11-19) |
| D-ART-08 | Stage E (финальные 2D-атласы H01) только после owner grip + Stage D confirm (T-131) (2026-11-19) |

## D-SCOPE — Отложенное

| ID | Решение |
|---|---|
| D-SCOPE-01 | Guild / PvP arena / events live — после базового вертикального среза и CH01; stubs + явная «недоступно» |
| D-SCOPE-02 | CH02+ не открывать игрокам, пока CH01 не завершён и не протестирован; контракты/закрытые переходы сохранить |
| D-SCOPE-03 | **2026-11-19 owner unlock:** полноценная разработка chat / DM / guilds / gacha / 36 heroes / progression / shop / VIP **без** ожидания CH01 accepted. CH02 и Stage E Kaeron atlases по-прежнему blocked. TEMP art явно помечать. Платные баннеры и реальные платежи — только после утверждения чисел. |
| D-SCOPE-04 | **2026-11-19:** H13–H36 Draft lore/abilities authorized for agent development; H01–H12 frozen; keep class/rarity/faction distribution; TEMP art only; mark Draft until final approve. |
| D-GACHA-01 | Preliminary rates: Standard N50/R35/SR12/SSR3; Advanced R70/SR24/SSR5/UR1. Pity advanced: SR every 10, SSR every 80 (replaces pull). Mythic event-only. Paid banners OFF until final approve. Admin-editable. |
| D-SHOP-01 | Shop live in TEST_PURCHASE mode: free grants with daily limits; show placeholder RUB prices + «Тестовый режим»; no payment provider; isolate from real revenue; architecture ready for real payments. |
| D-VIP-01 | VIP levels 0–10 preliminary; daily rewards; AFK bonuses; cosmetic; shop offers; points via TEST_PURCHASE for testing; PvP power bonus cap ≤5%; admin-editable. |
| D-AI-01 | Lunex GameBrain: architecture/docs only (`docs/LUNEX_GAMEBRAIN.md`); no VPS LLM install yet. |

## D-ADMIN — Админка / APK

| ID | Решение |
|---|---|
| D-ADMIN-01 | Admin: полноценная auth + RBAC (роли admin, viewer); API key только для доверенных сервисов; секреты не в клиенте; audit |
| D-ADMIN-02 | APK: проверить SDK/templates/keystore; не создавать новый релизный ключ если есть; не коммитить секреты; сначала debug APK, потом release |
| D-ADMIN-03 | Release keystore: искать на VPS/CI secrets; не создавать и не перезаписывать; пароли/ключи не в логах и не в git (2026-11-19) |
| D-ADMIN-04 | Пока только **debug APK**; release отложен до keystore владельца (Q1 2026-11-19) |

## D-PRODUCT — Продукт / платформа

| ID | Решение | Код GDD |
|---|---|---|
| D-PROD-01 | Android only | TECH-002 A |
| D-PROD-02 | Godot 4 + Go + PostgreSQL + Redis | TECH-001 C |
| D-PROD-03 | Портрет 9:16 | VIS-003 A |
| D-PROD-04 | 5 героев, автобой + ручные ультимейты, 2 линии | BATTLE-001 B, 002 C, 003 B |
| D-PROD-05 | 4 класса; 6 редкостей; 12 героев MVP | HERO-003 A, 004 B, 001 E |
| D-PROD-06 | Нет торговли между игроками | ECON-003 A |
| D-PROD-07 | Текстовые диалоги; кат-сцены не обязательны | STORY-003 D |
| D-PROD-08 | AFK офлайн ≤ 24 ч | AFK-003 C |
| D-PROD-09 | Игрок = командир без отдельного сюжетного аватара | STORY-PLAN / CAMPAIGN |

Полный реестр кодов — в `GDD.md`. Здесь не дублировать все 15 этапов дословно.

## D-V0 — Вертикальный срез (утверждено владельцем 2026-11-19)

| ID | Решение |
|---|---|
| D-V0-01 | Display-название **«БашЛегенды: Эпоха Абсурда»** показывать на **splash и home** |
| D-V0-02 | Internal ID: `BashLegends` |
| D-V0-03 | Диалоги: **статичные портреты**; без lipsync и сложной лицевой анимации |
| D-V0-04 | Боевые персонажи: **Blender 3D → анимация → прозрачные 2D-атласы → Godot 4** (уточнение VIS-001 C) |
| D-V0-05 | Стиль: Premium Clean Stylized Fantasy 2.5D; UI: Premium Fantasy Mobile UI |
| D-V0-06 | Состав среза: Splash, Home, L01, ARENA-L01, H01–H03, E01, Dialog CH01-Q01 |
| D-V0-07 | Не массовая генерация ассетов; не главы 02–12 на этапе V0 |
| D-V0-08 | Документация не считается готовым игровым прототипом |

## D-UI — Городской хаб (утверждено владельцем 2026-11-19)

| ID | Решение |
|---|---|
| D-UI-CITY-01 | **Stage 0 Canvas «Уфа, столица Абсурда» утверждён.** Home = интерактивный городской хаб (pan + 10 зданий + декор-анимации + тонкий resource bar + нижний nav «Город»), не dashboard из плиток. Перенос в Godot разрешён. Арена/events остаются locked stubs (D-SCOPE-01). TEMP-арт зданий/панорамы допустим до финальной генерации. Спека: `CITY_HUB_001.md` · задача T-159. |

## D-CONTENT — Статус контента (важно)

| ID | Решение |
|---|---|
| D-CONTENT-01 | `HEROES.md` и `CAMPAIGN_LOCATIONS.md` — **рабочие проектные пакеты**; V0 опирается на H01–H03 и L01 как срез стиля |
| D-CONTENT-02 | Не выдавать весь CH01/все 12 героев за «финально утверждённый лор», пока владелец не зафиксирует отдельно |
| D-CONTENT-03 | Сатира без реальных логотипов ведомств и без обвинений реальных организаций |

## Как добавить решение

1. Согласовать с владельцем.
2. Новая строка `D-…` с датой.
3. Обновить затронутый гайд.
4. Упомянуть в `ROAD.md` журнале и при необходимости в `STATUS.md`.
