# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `cursor/phase0-design-docs-beaf` → `main`  
> Playable V0-C stub + Phase 0 spec + CI. Это **не** полный MVP.

## NOW (текущий фокус)

**Только что закрыто подряд:** `T-050` → `T-020` → `T-021`.  
**Дальше:** расширение CH01 на моках (B02+) **или** тонкий `ApiClient` по PHASE0_SPEC; T-031 при Blender.  
**Запрещено:** главы 02–12; массовые ассеты вне очереди; rename; «MVP готов».

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md).

## Сводка статусов

| Область | Статус | Доказательство |
|---|---|---|
| Docs / VIS / V0 decisions | ГОТОВО | `docs/` |
| V0-A/B/C client stub | ГОТОВО (stub) | `client/` |
| V0-D review / stop-line | ГОТОВО (пакет) | `docs/V0_REVIEW.md` |
| Phase 0 API contracts | ГОТОВО (спека) | `docs/PHASE0_SPEC.md` |
| CI | ГОТОВО (workflow) | `.github/workflows/ci.yml` |
| Blender atlases T-031 | BLOCKED | нет Blender |
| Backend Go | НЕ НАЧАТО | — |

## Что сделано

1. Playable flow + autofight B01 + rewards.  
2. V0 review + стоп-линия.  
3. PHASE0_SPEC (данные/HTTP/безопасность).  
4. CI: JSON validate + Godot smoke V0-A/C + docs presence.  
5. Local: `scripts/ci_validate.sh`.

## Очерёдность

```
DONE: … T-040 → T-050 → T-020 → T-021
 → CH01 B02–B04 на моках и/или ApiClient mock switch
 → T-031 при Blender
 → ROAD Фаза 1 клиент MVP
```
