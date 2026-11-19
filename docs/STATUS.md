# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `cursor/ch01-campaign-embed-beaf` → `cursor/phase0-design-docs-beaf`  
> Playable V0-C stub + **CH01 campaign embed** (12 квестов / 30 боёв на моках). Это **не** полный MVP.

## NOW (текущий фокус)

**Закрыто:** `T-055` — CH01 данные + CampaignCatalog + прогрессия + UI кампании.  
**Дальше:** `ApiClient` (USE_MOCK) **или** арт L02–L10 (`T-060`); T-031 при Blender.  
**Запрещено:** главы 02–12; массовые ассеты вне очереди; rename; «MVP готов».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md).

## Сводка статусов

| Область | Статус | Доказательство |
|---|---|---|
| Docs / VIS / V0 decisions | ГОТОВО | `docs/` |
| V0-A/B/C client stub | ГОТОВО (stub) | `client/` |
| CH01 campaign embed | ГОТОВО (моки) | `client/data/` + `CampaignCatalog` + smoke_ch01 |
| V0-D review / stop-line | ГОТОВО (пакет) | `docs/V0_REVIEW.md` |
| Phase 0 API contracts | ГОТОВО (спека) | `docs/PHASE0_SPEC.md` |
| CI | ГОТОВО | `.github/workflows/ci.yml` (+ smoke_ch01) |
| Blender atlases T-031 | BLOCKED | нет Blender |
| Backend Go | НЕ НАЧАТО | — |

## Что сделано

1. Playable flow + autofight + rewards.  
2. V0 review + стоп-линия.  
3. PHASE0_SPEC (данные/HTTP/безопасность).  
4. CI: JSON validate + Godot smoke V0-A/C/CH01 + docs presence.  
5. **CH01:** 12 quests / 11 locs / 29 enemies / 30 battles / 12 dialogues → клиент; кампания Home→Campaign→Location→Dialog→Battle chain.

## Очерёдность

```
DONE: … T-040 → T-050 → T-020 → T-021 → T-055
 → ApiClient mock switch и/или T-060 арт L02+
 → T-031 при Blender
 → ROAD Фаза 1 клиент MVP
```
