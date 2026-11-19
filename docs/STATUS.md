# STATUS.md — Единый снимок состояния проекта

> **Канон для ИИ и людей.** Обновлять в конце каждого значимого шага.  
> Дата снимка: **2026-11-19** · Ветка работы: `cursor/phase0-design-docs-beaf` · сливать в `main`  
> Документы ≠ полный прототип. V0-A каркас клиента: **есть** (`client/`).

## NOW (текущий фокус)

**Следующая задача:** `T-020` (Phase 0 API/contracts) **или** `T-030` (V0-B точечный арт) — по приоритету владельца.  
**Только что завершено:** `T-010` V0-A Godot skeleton.  
**Не делать сейчас:** массовая генерация ассетов; главы 02–12; rename repo/package; объявление MVP готовым.

Полная очередь: [`TASK_QUEUE.md`](TASK_QUEUE.md).

## Сводка статусов

| Область | Статус | Доказательство |
|---|---|---|
| GDD каркас | СПЕЦИФИКАЦИЯ КАРКАСА УТВЕРЖДЕНА | `GDD.md` |
| ROAD / журнал | ВЕДЁТСЯ | `ROAD.md` |
| Навигация для ИИ | ГОТОВО | `AGENTS.md`, STATUS, TASK_QUEUE, DECISIONS, INDEX |
| Решения V0 | УТВЕРЖДЕНО | `DECISIONS.md` |
| План V0 | ГОТОВ | `V0_IMPLEMENTATION_PLAN.md` |
| **Godot-клиент V0-A** | **ГОТОВО (каркас)** | `client/project.godot`, сцены, smoke OK |
| Ассеты (арт/атласы) | НЕ НАЧАТО | placeholders only |
| Backend Go/API | НЕ НАЧАТО | — |
| CI GitHub Actions | НЕ НАЧАТО | — |
| Главы 02–12 | НЕ НАЧАТО | — |

## Что сделано (факты)

1. Документы дизайна + AI handoff в `main`.
2. Решения V0 утверждены.
3. **V0-A:** Godot 4.3 проект `client/` — Splash → Home → L01 → Dialog CH01-Q01 → Battle stub → Home.
4. Название на splash/home; диалог со static portrait placeholder; токены палитры; JSON мок 10 реплик.
5. Headless smoke: `godot --headless --path client -s res://scripts/tools/smoke_v0a.gd` → EXIT 0.

## Чего нет

- Нет финального арта / Blender-атласов.
- Нет реального автобоя / RPG-цифр.
- Нет Android package ID / APK.
- Нет сервера и CI.
- Это **не** готовый игровой прототип MVP — только каркас V0-A.

## Очерёдность верхнего уровня

```
DONE: docs + V0 decisions + AI index + T-010 V0-A skeleton
 → T-020 Phase 0 API contracts (параллельно можно)
 → T-030 V0-B точечный арт среза
 → T-031 Blender→atlas пилот H01
 → T-040 V0-C сборка demo-path с артом
 → T-050 V0-D review
 → далее ROAD Фаза 1; НЕ главы 02–12 до разрешения
```

## Как обновлять этот файл

После каждой задачи: сдвинуть NOW → обновить таблицу → `TASK_QUEUE` → журнал `ROAD.md` §8 → commit/push → merge в `main`.
