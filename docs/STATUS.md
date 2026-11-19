# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main` (+ UI art `cursor/ui-art-shop-home-beaf`)  
> Аудит: [`reports/ONLINE_SYSTEMS_AUDIT.md`](reports/ONLINE_SYSTEMS_AUDIT.md) · Спека: [`ONLINE_SYSTEMS_SPEC.md`](ONLINE_SYSTEMS_SPEC.md)  
> Отчёт CH01: [`reports/CH01_ACCEPTANCE_TEST_2026-11-19.md`](reports/CH01_ACCEPTANCE_TEST_2026-11-19.md)

## NOW

MONSTERS-CH01-001: 29 уникальных TEMP-концептов, серверные умения/фазы, Бестиарий.  
Мультифрейм-атласы/VFX ещё MISSING. Финальный арт **не** Stage E (D-ART-06). CH02 blocked.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | Live API auth/battle/rewards; progression; gacha pity Draft; TEST_PURCHASE shop; VIP daily; chat WS+PG; guild roles/quests/vault/board; admin mute/delete/reports; EQUIPMENT-001 instances + combat flats/sets |
| **Частично** | H13–H36 TEMP art (не Stage E); home/shop/VIP UI на TEMP ассетах; awaken/skills depth; equipment TEMP icons (не финальный арт) |
| **Заглушки** | Real payments OFF (`T-153`); paid gacha OFF; equipment random drop OFF; guild wars/boss; CH02; GameBrain runtime; arena/events live |

## BLOCKED / ждёт владельца

| ID | Что | Условие снятия |
|---|---|---|
| T-128 | CH01 accepted | Device/review (не блокирует online systems) |
| T-131 | H01 grip + Stage E | Owner Blender |
| T-126 / T-129 | Release APK / phone URL | Keystore / LAN URL |
| T-090 | CH02 | Отдельное разрешение |
| T-153 | Real payment provider | Owner + D-SHOP-01 |

## Известные ограничения

- Shop = `TEST_PURCHASE` only (не реальные платежи; дневные лимиты).
- Весь новый арт помечен TEMP — не финальный Stage E.
- Arena/events UI «НЕДОСТУПНО» (D-SCOPE-01).
