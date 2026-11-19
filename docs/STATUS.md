# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main`  
> Phase 0–2 stub-линия закрыта до T-102. Релизный online/APK и Фаза 3 — не начаты.

## NOW (текущий фокус)

**Закрыто только что:** T-101 ultimates в server sim · T-102 client seed sync · T-103 `PHASE2_AUDIT`.  
**Дальше (нужен выбор владельца):** signed APK · RBAC admin · guild/arena live · T-031 Blender · или PX главы 02–12.  
**Запрещено без разрешения:** главы 02–12 · rename · массовый арт.

Очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md) · Аудит: [`PHASE2_AUDIT.md`](PHASE2_AUDIT.md) · Сервер: [`../server/README.md`](../server/README.md).

## Сводка по фазам ROAD

| Фаза | Статус | Комментарий |
|---|---|---|
| 0 Docs / contracts | ГОТОВО | |
| V0 A–D + CH01 embed | ГОТОВО (stub art) | T-031 Blender BLOCKED |
| 1 Client MVP screens | ГОТОВО на моках | APK у владельца |
| 2 Server + mock replace | ГОТОВО как stub/opt-in | Default client всё ещё mock |
| 3 Acceptance | НЕ НАЧАТО | Нужен режим без моков + signed APK |
| 4 Post-MVP | НЕ НАЧАТО | |

## Needs owner (уточнения)

1. **T-031** — есть ли Blender/pipeline локально, или оставляем still sprites?
2. **APK** — дать SDK/keystore / собирать у владельца?
3. **Ультимейты** — сервер auto-cast OK как античит-база, или нужен полный replay действий?
4. **Guild/arena/events** — оставляем stubs до отдельного приоритета?
5. **Admin RBAC** — нужен ли сейчас, или хватает открытых metrics?
6. **PX** — открывать главы 02–12 / rename / mass art?

## Очерёдность

```
DONE: Phase2 → T-100…T-103
 → владелец выбирает: APK | RBAC | guild-live | Blender | CH02+
```
