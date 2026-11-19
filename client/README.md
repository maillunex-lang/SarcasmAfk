# Client (Godot 4.3) — V0-C playable stub

Display: **БашЛегенды: Эпоха Абсурда** (`BashLegends`)  
Not a finished MVP. Combat stats are placeholders. Blender atlases pending (T-031 blocked in this environment).

## Run

```bash
godot4 --path /workspace/client
```

## Smoke

```bash
godot4 --headless --path /workspace/client -s res://scripts/tools/smoke_v0a.gd
godot4 --headless --path /workspace/client -s res://scripts/tools/smoke_v0c.gd
```

## Playable flow

1. Splash → Home  
2. Campaign → L01  
3. Dialog CH01-Q01 (static portraits)  
4. Autofight B01 (manual ultimates, speed ×1/×2)  
5. First-clear reward (idempotent) → Home  

## Key code

| Path | Role |
|---|---|
| `scripts/autoload/game_state.gd` | Save/load, rewards, party |
| `scripts/battle/battle_engine.gd` | ATB autofight |
| `data/battles/B01.json` | Encounter |
| `data/heroes/roster_v0.json` | Party stats |
| `assets/` | Draft art (see ASSET_MANIFEST.md) |
