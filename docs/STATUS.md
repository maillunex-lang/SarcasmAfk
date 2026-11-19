# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (Phase 2 admin + live toggle T-093…T-096)  
> Клиент: моки по умолчанию, live toggle в More. API: memory / Postgres+Redis + metrics.

## NOW (текущий фокус)

**Закрыто:** `T-093`…`T-096` — readyz/metrics, request logging, UI live toggle, backup script.  
**Дальше:** полный tick-sim боёв **или** load tests / APK online.  
**Запрещено:** главы 02–12; rename; «релиз без моков».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md). Сервер: [`server/README.md`](../server/README.md).

## Сводка

| Область | Статус |
|---|---|
| Клиент Phase1 + art | ГОТОВО (stub) |
| Go API + PG/Redis | ГОТОВО (opt-in) |
| Live toggle / metrics | ГОТОВО |
| Full tick-sim / APK | НЕ НАЧАТО |
| Blender T-031 | BLOCKED |

## Очерёдность

```
DONE: T-085 → T-093…T-096
 → tick-sim / load / APK
 → T-031 при Blender
```
