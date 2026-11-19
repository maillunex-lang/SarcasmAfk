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

- Сделано: docs + draft-арт + **играбельный V0-C stub** (Splash→Home→L01→Dialog→autofight B01→награда).
- Дальше: review / Phase 0 API / Blender-атласы когда доступны.
- Запрещено: массовые ассеты вне очереди, главы 02–12, rename.

```bash
godot4 --path client
godot4 --headless --path client -s res://scripts/tools/smoke_v0a.gd
godot4 --headless --path client -s res://scripts/tools/smoke_v0c.gd
```


## Ветки

- `main` — канон  
- `cursor/phase0-design-docs-beaf` — текущая рабочая ветка (сливать в `main`)
