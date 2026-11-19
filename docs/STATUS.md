# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `cursor/online-systems-p1-beaf`  
> Аудит: [`reports/ONLINE_SYSTEMS_AUDIT.md`](reports/ONLINE_SYSTEMS_AUDIT.md) · Спека: [`ONLINE_SYSTEMS_SPEC.md`](ONLINE_SYSTEMS_SPEC.md)  
> Отчёт CH01: [`reports/CH01_ACCEPTANCE_TEST_2026-11-19.md`](reports/CH01_ACCEPTANCE_TEST_2026-11-19.md)

## NOW

P3: chat moderation admin + guild quests/vault/board. Stack: #17 → #18 → online-p3.  
CH02 + Stage E blocked. CH01 not accepted.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | P2 systems + admin mute/delete/reports; guild donate/quests/board; war/boss hook tables empty |
| **Частично** | Chat still in-memory (PG tables exist; T-154 wire); awaken/skills depth |
| **Заглушки** | Real payments OFF; paid gacha OFF; guild wars; CH02; GameBrain runtime |

## BLOCKED / ждёт владельца

| ID | Что | Условие снятия |
|---|---|---|
| T-128 | CH01 accepted | Device/review (не блокирует online systems) |
| T-131 | H01 grip + Stage E | Owner Blender |
| T-126 / T-129 | Release APK / phone URL | Keystore / LAN URL |
| T-090 | CH02 | Отдельное разрешение |
| Draft knobs | H13–H36 names, gacha rates, VIP/shop prices | Owner approval |

## Известные ограничения

- Shop = `purchase_mode: simulated` only (не реальные платежи).
- Chat hub in-memory until PG persistence wired end-to-end.
- WebSocket chat — следующий срез (P3); сейчас REST history/send + rate limit.
