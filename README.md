# SarcasmAfk

Сатирическая онлайн AFK RPG (Android · Godot 4).  
**Display:** БашЛегенды: Эпоха Абсурда · **Internal:** `BashLegends`  
Репозиторий / package ID **не** переименовывать без отдельного решения.

## Для любого ИИ / нового участника

Читать строго по порядку:

1. [AGENTS.md](AGENTS.md)  
2. [docs/STATUS.md](docs/STATUS.md) — **что сделано и что сейчас**  
3. [docs/TASK_QUEUE.md](docs/TASK_QUEUE.md) — **очерёдность**  
4. [docs/DECISIONS.md](docs/DECISIONS.md)  
5. [docs/INDEX.md](docs/INDEX.md) — карта всех документов  

Документация **не** является играбельным прототипом. Кода клиента и ассетов пока нет.

## Быстрый статус (см. актуальный STATUS.md)

- Сделано: docs + V0 decisions + **`client/` Godot 4.3 V0-A skeleton** (Splash→Home→L01→Dialog→Battle).
- Дальше: **T-030** точечный арт V0-B и/или **T-020** Phase 0 API.
- Запрещено сейчас: массовые ассеты, главы 02–12, rename.

```bash
godot4 --path client
# smoke:
godot4 --headless --path client -s res://scripts/tools/smoke_v0a.gd
```


## Ветки

- `main` — канон  
- `cursor/phase0-design-docs-beaf` — текущая рабочая ветка (сливать в `main`)
