# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `cursor/online-systems-p1-beaf`  
> Аудит: [`reports/ONLINE_SYSTEMS_AUDIT.md`](reports/ONLINE_SYSTEMS_AUDIT.md) · Спека: [`ONLINE_SYSTEMS_SPEC.md`](ONLINE_SYSTEMS_SPEC.md)  
> Отчёт CH01: [`reports/CH01_ACCEPTANCE_TEST_2026-11-19.md`](reports/CH01_ACCEPTANCE_TEST_2026-11-19.md)

## NOW

P1–P2 online foundation **в работе/срезано**: 36-hero Draft catalog, progression API, chat/guild/shop/VIP skeleton.  
D-SCOPE-03: online systems unlocked without CH01 accept. CH02 + Stage E still blocked.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | CH01 vertical; auth/battles/rewards; hero level-up/star-up API; global chat REST; guild create/join; simulated shop; VIP status Draft; roster 36 |
| **Частично** | Gacha (tickets + crypto pick; pity/rates Draft); guild roles/quests; chat WS/DM moderation; progression awaken/skills; admin config UI |
| **Заглушки** | Real payments OFF; paid gacha banners OFF; arena/events stubs; CH02 closed; TEMP art H13–H36 |

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
