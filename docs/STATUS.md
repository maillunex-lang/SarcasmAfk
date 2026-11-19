# STATUS.md — Единый снимок состояния проекта

> **Канон для ИИ и людей.** Обновлять в конце каждого значимого шага.  
> Дата снимка: **2026-11-19** · Ветка: `cursor/phase0-design-docs-beaf` → `main`  
> Играбельный stub V0-C есть; это **не** полный MVP.

## NOW (текущий фокус)

**Следующее:** review V0 (`T-050`) / `T-020` API / подготовка T-031 когда появится Blender.  
**Сделано только что:** `T-040` V0-C — autofight B01, GameState, награды, quest flag.  
**Не делать:** главы 02–12; массовые ассеты вне очереди; rename; объявлять MVP готовым.

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md).

## Сводка статусов

| Область | Статус | Доказательство |
|---|---|---|
| Docs / VIS / V0 decisions | ГОТОВО (спека) | `docs/` |
| Godot V0-A skeleton | ГОТОВО | `client/` scenes |
| Draft art V0-B | ГОТОВО (draft) | `client/assets/` |
| **Playable V0-C** | **ГОТОВО (stub)** | GameState + BattleEngine + B01 |
| Blender atlases T-031 | BLOCKED | нет Blender в среде |
| Backend / CI | НЕ НАЧАТО | — |

## Что сделано (факты)

1. Документы + AI handoff + draft-арт.
2. Клиент: Splash→Home→L01→Dialog→**autofight B01**→награда→Home.
3. `GameState` save/load, idempotent first-clear reward.
4. Ручные ультимейты + скорость ×1/×2.
5. Smoke: `smoke_v0a.gd`, `smoke_v0c.gd` EXIT 0.

## Чего нет

- Финальный баланс / 5 героев всегда / полный CH01.
- Blender combat atlases.
- Сервер, CI, APK.
- AFK экономика.

## Очерёдность

```
DONE: … → T-040 V0-C playable stub
 → T-050 review / T-020 API
 → T-031 когда есть Blender
 → ROAD Фаза 1 (не главы 02–12)
```
