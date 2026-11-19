# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (Phase 2 live API T-086…T-089)  
> Клиент по умолчанию на моках; live HTTP готов. Postgres/Redis ещё нет (T-085).

## NOW (текущий фокус)

**Закрыто:** `T-086`…`T-089` — live ApiClient, file persist, battle session gate, integration smoke.  
**Дальше:** `T-085` Postgres+Redis+full battle sim **или** UX live-toggle.  
**Запрещено:** главы 02–12; rename; «релиз без моков».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md). Сервер: [`server/README.md`](../server/README.md).

## Сводка

| Область | Статус |
|---|---|
| Клиент Phase1 + art | ГОТОВО (stub) |
| Go API Phase2 stub | ГОТОВО |
| Live ApiClient HTTP | ГОТОВО (opt-in) |
| Persist / session gate | ГОТОВО (file) |
| Postgres / Redis | НЕ НАЧАТО (T-085) |
| Blender T-031 | BLOCKED |

## Очерёдность

```
DONE: T-081…T-084 → T-086…T-089
 → T-085 harden store / full battle sim
 → T-031 при Blender
```
