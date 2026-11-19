# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (Phase 2 Go API stub T-081…T-084)  
> Клиент MVP на моках + Go API stub. Postgres/Redis ещё нет.

## NOW (текущий фокус)

**Закрыто:** `T-081`…`T-084` — Go API (auth/progress/rewards/AFK/gacha/battles/guild/arena/events).  
**Дальше:** `T-085` Postgres+Redis+battle verify **или** интеграция клиента `USE_MOCK=false`.  
**Запрещено:** главы 02–12; rename; «релиз без моков».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md). Сервер: [`server/README.md`](../server/README.md).

## Сводка

| Область | Статус |
|---|---|
| Клиент Phase1 + art | ГОТОВО (stub) |
| Go API Phase2 stub | ГОТОВО |
| Postgres / Redis | НЕ НАЧАТО (T-085) |
| Blender T-031 | BLOCKED |

## Очерёдность

```
DONE: T-060/T-061 → T-081…T-084
 → T-085 harden store / client live API
 → T-031 при Blender
```
