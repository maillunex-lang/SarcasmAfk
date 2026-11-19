# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (T-056 ApiClient)  
> Playable V0-C + CH01 campaign + тонкий `ApiClient` (`USE_MOCK=true`). Это **не** полный MVP.

## NOW (текущий фокус)

**Закрыто:** `T-056` — `ApiClient` с локальными моками (content/progress/battles/rewards).  
**Дальше:** `T-060` арт L02–L10 **или** `T-070` MVP-экраны; T-031 при Blender.  
**Запрещено:** главы 02–12; массовые ассеты вне очереди; rename; «MVP готов».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md).

## Сводка статусов

| Область | Статус | Доказательство |
|---|---|---|
| Docs / VIS / V0 decisions | ГОТОВО | `docs/` |
| V0-A/B/C client stub | ГОТОВО (stub) | `client/` |
| CH01 campaign embed | ГОТОВО (моки) | `client/data/` + CampaignCatalog |
| ApiClient USE_MOCK | ГОТОВО | `client/scripts/net/api_client.gd` + smoke_api |
| V0-D review / stop-line | ГОТОВО (пакет) | `docs/V0_REVIEW.md` |
| Phase 0 API contracts | ГОТОВО (спека) | `docs/PHASE0_SPEC.md` |
| CI | ГОТОВО | `.github/workflows/ci.yml` |
| Blender atlases T-031 | BLOCKED | нет Blender |
| Backend Go | НЕ НАЧАТО | — |

## Что сделано

1. Playable flow + autofight + rewards.  
2. V0 review + стоп-линия.  
3. PHASE0_SPEC + CI.  
4. CH01: 12Q / 30B / 12 диалогов в клиенте.  
5. **ApiClient** (`USE_MOCK`): heroes/battles/dialogues/quests/progress/claim/start/finish.

## Очерёдность

```
DONE: … T-055 → T-056
 → T-060 арт L02+ и/или T-070 MVP экраны
 → T-031 при Blender
 → ROAD Фаза 1 клиент MVP
```
