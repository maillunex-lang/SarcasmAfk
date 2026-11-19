# AGENTS.md — Обязательная инструкция для любого ИИ

Читать **в этом порядке** перед любой работой:

1. [`docs/STATUS.md`](docs/STATUS.md) — что сделано / не сделано / текущий фокус  
2. [`docs/TASK_QUEUE.md`](docs/TASK_QUEUE.md) — очерёдность задач  
3. [`docs/DECISIONS.md`](docs/DECISIONS.md) — утверждённые решения (не менять без владельца)  
4. [`docs/INDEX.md`](docs/INDEX.md) — карта документов  
5. Затем профильный файл задачи (`GDD`, `ROAD`, `V0_IMPLEMENTATION_PLAN`, …)  
6. **Проверить фактический код/ассеты в репозитории** — документы ≠ доказательство реализации

## Проект (кратко)

| Поле | Значение |
|---|---|
| Repo | `SarcasmAfk` (не переименовывать) |
| Display name | БашЛегенды: Эпоха Абсурда |
| Internal ID | `BashLegends` |
| Platform | Android only · Godot 4 · 9:16 |
| Stack later | Go + PostgreSQL + Redis |
| Working branch | `cursor/phase0-design-docs-beaf` (синхронизировать с `main`) |

## Жёсткие правила

- Не объявлять модуль `ГОТОВО` без тестов/аудита и записи в `STATUS.md` + `ROAD.md`.
- Не менять утверждённые коды GDD (CONCEPT/HERO/BATTLE/…) без нового решения владельца.
- Не массово генерировать ассеты вне текущего пункта `TASK_QUEUE`.
- Не начинать главы 02–12, пока очередь явно не откроет этот этап.
- Не переименовывать repo / Android package ID.
- Документация **не** является игровым прототипом.
- После значимого шага: обновить `STATUS.md`, `TASK_QUEUE.md`, журнал в `ROAD.md`, затем commit/push.

## Быстрый ответ «где мы?»

Смотри блок **NOW** в [`docs/STATUS.md`](docs/STATUS.md).

Клиент V0-A: [`client/`](client/) (Godot 4.3). Это каркас, не готовый MVP.
