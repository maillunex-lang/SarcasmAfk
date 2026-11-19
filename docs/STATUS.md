# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `cursor/ch01-game-polish-beaf`  
> Отчёт CH01: [`reports/CH01_ACCEPTANCE_TEST_2026-11-19.md`](reports/CH01_ACCEPTANCE_TEST_2026-11-19.md)  
> Уточнения: [`OWNER_CLARIFICATIONS.md`](OWNER_CLARIFICATIONS.md)

## NOW

CH01 **не accepted**. T-133/T-134 DONE (баланс B02+, UX Heroes/Inventory/AFK/Gacha).  
Ждём владельца: T-128 accept · T-131 grip/Stage E · T-129 phone URL · T-126 keystore.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | CH01 цепочка (mock+live smokes); debug APK; live API localhost; ATB+replay; manual ULT↔auto_cast; Home continue; party portraits |
| **Частично** | Combat H01–H03/E01 drafts; баланс pass-2 (B01–B30 HP floor); live URL только 127.0.0.1 |
| **Заглушки / mock** | Debug → mock по умолчанию на устройстве без URL; guild/arena/events «НЕДОСТУПНО»; CH02+ закрыт |

## BLOCKED / ждёт владельца

| ID | Что | Условие снятия |
|---|---|---|
| T-128 | CH01 accepted | Явное «принято» после device/review отчёта |
| T-131 | H01 grip + Stage E | Owner Blender grip + Stage D confirm |
| T-127 | Art approve | Accept / reject финального арта |
| T-126 | Release APK | Keystore через secrets **или** оставить debug (сейчас debug) |
| T-129 | Phone live URL | LAN/VPS/домен в `client_config` / secrets |
| T-112 | Guild/arena/events live | После T-128 |
| T-090…092 | CH02 / mass art / rename | Явное PX-разрешение |

## Известные ограничения

- Release keystore на агенте не найден; GH secrets не читаются (403).
- Debug APK ~131MB.
- `client_config.json` → `http://127.0.0.1:8080/v1` (телефоны без LAN/VPS URL остаются на mock).
