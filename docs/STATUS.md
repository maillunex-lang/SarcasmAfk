# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (после PR #14)  
> Дорожная карта актуализирована: [`ROAD.md`](ROAD.md) §0/§9 · уточнения: [`OWNER_CLARIFICATIONS.md`](OWNER_CLARIFICATIONS.md)

## NOW

Ждём ответы владельца по **T-126…T-129** (keystore, art-approve, CH01 accepted, live URL).  
Код вертикального среза и debug APK — готовы. P3 / CH02 не стартуем.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | CH01 цепочка на клиенте; debug APK; live API (auth/battle/rewards/resume); server ATB+replay; admin RBAC stub; CI |
| **Частично** | Combat H01–H03/E01 — pipeline drafts; release preset без подписи; баланс ATB placeholder |
| **Заглушки / mock** | Debug → mock по умолчанию; guild/arena/events «НЕДОСТУПНО»; CH02+ закрыт; H04–H12 combat placeholders |

## BLOCKED / ждёт владельца

| ID | Что | Условие снятия |
|---|---|---|
| T-126 | Release APK | Действующий keystore через secrets **или** явный «только debug» |
| T-127 | Art approve | Accept / reject+правки по H01–H03/E01 |
| T-128 | CH01 accepted | Явное принятие или список дефектов |
| T-129 | Live URL | URL API для телефонов или «offline-only» |
| T-112 | Guild/arena/events live | После T-128 |
| T-090…092 | CH02 / mass art / rename | Явное PX-разрешение |

## Известные ограничения

- Release keystore на VPS/агенте не найден; GH secrets агенту не читаются (403).
- Debug APK ~131MB (локации/арт).
- Ультимейт в коротких боях накапливается медленно — в smoke энергия форсится для проверки команды.
