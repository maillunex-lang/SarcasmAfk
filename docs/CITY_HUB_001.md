# CITY-HUB-001 — Уфа, столица Абсурда

> Stage 0 Canvas approved by owner **2026-11-19** · Decision **D-UI-CITY-01**  
> Vertical slice task: **T-159** · Branch: `cursor/city-hub-stage-g-4106`

## 1. Goal

Replace dashboard-style Home with an interactive **2.5D city hub** matching the approved Stage 0 Canvas: pan camera, 10 building hotspots, satirical decor, thin resource bar, bottom nav («Город»).

## 2. Design system (locked for city hub)

| Token / rule | Value |
|---|---|
| Style | Premium Clean Stylized Anime Fantasy · hybrid 2.5D city |
| Orientation | 9:16 (+ tall Android frames) |
| Brand colors | navy `#101C35` / gold `#E8BC68` / cyan `#54D9DA` / ivory `#F5F0E5` (DesignTokens) |
| Home composition | Full-bleed city scene — **not** a 2×3 tile dashboard |
| Primary CTA | Mid-quest continue strip **or** building «Врата Кампании» |
| Secondary | Building hotspots + bottom nav |
| Locked | Arena / live events remain stubs (D-SCOPE-01) |
| Player-facing copy | No internal ids (`H01`, `CH01-Q…`) on hub chrome |

Fonts / buttons / panels: existing `DesignTokens` + `bashlegends_theme.tres`.

## 3. Screen map (hub destinations)

| Building | Dest scene | Notes |
|---|---|---|
| Башня Призыва | Gacha | notify badge |
| Палата Гильдий | Guild | |
| Таверна Героев | Heroes | |
| Кузница | Inventory | |
| Лавка Чудес | Shop | TEST_PURCHASE only |
| Врата Кампании | Campaign | notify |
| Арена | Arena | **locked** stub |
| Экспедиционный причал | Expedition | |
| Ратуша Абсурда | More | satirical board entry |
| AFK-хранилище | AFK | hours badge |

Bottom nav: Город · Карта · Герои · AFK · Ещё (`HubChrome`).

## 4. Godot architecture (vertical slice)

```
home.tscn
  └─ home.gd (city hub)
       ├─ CityClip (drag pan)
       │    └─ CityWorld 2400×1400
       │         ├─ sky/far/mid/road TextureRect layers
       │         ├─ Building_* hotspots (Button)
       │         └─ decor (dragon, marshrutka, papers, stamp, queue)
       ├─ CityTopBar (currencies)
       ├─ optional mid-quest CTA
       ├─ CityTip
       └─ HubNav
```

Data: `client/data/city/ufa_buildings.json`  
TEMP art: `client/assets/city/ufa/*` via `scripts/generate_city_ufa_temp.py`  
Smoke: `client/scripts/tools/smoke_city_hub.gd`

## 5. Asset checklist

| Asset | Status | Notes |
|---|---|---|
| `city_ufa_sky/far/mid/road/panorama.jpg` | TEMP | Generator; final isometric pass later |
| Building silhouettes / iso props | TEMP | Code-built panels + icons until art pack |
| Decor sprites (dragon, marshrutka) | TEMP | Color panels; replace with sprites |
| Nav / currency icons | DONE | Existing `ui_icon_*` |
| Final Kaeron Stage E | BLOCKED | T-131 |

## 6. Stage plan after slice

1. Owner device playtest of hub feel  
2. Replace TEMP panorama with painted 2.5D layers  
3. Distinct isometric meshes/sprites per building  
4. Polish decor anims + audio stingers  
5. Optional building interior scenes (not required for slice)

## 7. Non-goals

- CH02 unlock, real payments, Stage E atlases, arena live  
- Mass `.import` commits  
- Production API changes for hub itself
