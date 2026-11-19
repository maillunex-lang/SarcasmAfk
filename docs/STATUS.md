# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (Phase 2 Postgres/Redis T-085)  
> Клиент по умолчанию на моках; API: memory **или** Postgres+Redis. Soft battle verify включён.

## NOW (текущий фокус)

**Закрыто:** `T-085` — Postgres store, Redis sessions/idempotency, soft battle verify, docker-compose, CI services.  
**Дальше:** админка/мониторинг **или** UI live-toggle **или** полный tick-sim.  
**Запрещено:** главы 02–12; rename; «релиз без моков».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md). Сервер: [`server/README.md`](../server/README.md).

## Сводка

| Область | Статус |
|---|---|
| Клиент Phase1 + art | ГОТОВО (stub) |
| Go API + live client | ГОТОВО |
| Postgres + Redis | ГОТОВО (opt-in) |
| Soft battle verify | ГОТОВО |
| Full tick-sim / admin | НЕ НАЧАТО |
| Blender T-031 | BLOCKED |

## Очерёдность

```
DONE: T-081…T-089 → T-085
 → admin/monitoring / UI live-toggle / full battle sim
 → T-031 при Blender
```
