# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main`  
> Решения владельца D-COMBAT/D-NET/D-ART/D-SCOPE/D-ADMIN зафиксированы. P0 в работе.

## NOW (текущий фокус)

**P0 закрыто в этом батче:** авторитетный replay finish · battle commands · admin RBAC lock · live probe без silent mock · guild/arena/events явно «недоступно».  
**Дальше P0/P1:** сохранения/переподключение · debug APK probe · Blender pipeline scripts · CH01 polish.  
**Запрещено:** CH02+ для игроков · mass art как финал · production-конфиг без согласования.

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md) · Решения: [`DECISIONS.md`](DECISIONS.md) · Аудит: [`PHASE2_AUDIT.md`](PHASE2_AUDIT.md).

## Что реально работает

| Область | Статус |
|---|---|
| Mock client + Godot smokes | Работает |
| Live API (opt-in) + probe | Работает (нужен поднятый server) |
| Auth anonymous / progress / rewards | Работает |
| Battle start → command → finish replay | Работает (server victory + reward) |
| Admin metrics | Работает только с `ADMIN_API_KEY` |
| Postgres/Redis opt-in | Работает при env |

## Частично

| Область | Статус |
|---|---|
| Client↔server combat parity | Seed+auto-cast; ручные ульты как команды (tick approx) |
| Live default для APK | Probe готов; APK ещё не собирается |
| Art | Placeholders ≠ финал (D-ART-02) |

## Заглушки

| Область | Статус |
|---|---|
| Guild / Arena / Events live | UI «НЕДОСТУПНО» (D-SCOPE-01) |
| Signed APK | Только export example |
| Blender pipeline | Не начат (T-031) |
| CH02+ | Закрыто (D-SCOPE-02) |

## Очерёдность

```
DONE: decisions + P0 auth battle/live/admin lock
 → P0 saves/reconnect · P1 debug APK · Blender scripts · CH01
```
