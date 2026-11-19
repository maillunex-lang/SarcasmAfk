# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (Phase 2 tick-sim + load T-097…T-100)  
> Server ATB tick-sim — источник истины для finish. Load smoke в CI. APK preset — stub.

## NOW (текущий фокус)

**Закрыто:** `T-097`…`T-100` — ATB tick-sim, finish wiring, load smoke, Android export example.  
**Дальше:** подписанный APK (SDK) **или** ultimates в sim **или** T-031.  
**Запрещено:** главы 02–12; rename; «релиз без моков».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md). Сервер: [`server/README.md`](../server/README.md).

## Сводка

| Область | Статус |
|---|---|
| Клиент Phase1 + art | ГОТОВО (stub) |
| Go API + PG/Redis | ГОТОВО |
| ATB tick-sim verify | ГОТОВО |
| Load smoke | ГОТОВО |
| Signed APK | НЕ НАЧАТО (нужен SDK) |
| Blender T-031 | BLOCKED |

## Очерёдность

```
DONE: T-093…T-096 → T-097…T-100
 → APK / ultimates-in-sim / T-031
```
