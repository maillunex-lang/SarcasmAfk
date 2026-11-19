# CH01 RPG Expansion E2E Report — 2026-11-19 (T-157)

> Владелец: **это отчёт прогона Slice E, не device-accept CH01** (T-128 по-прежнему BLOCKED).  
> Ветка: `cursor/t157-ch01-expansion-e2e-4106` · Debug APK: `build/BashLegends-debug.apk` (~393MB)

## 1. Scope under test

CH01 Expansion matrix (SQ01–SQ05, POI-01…10, EX-01…06, journal, skill-up, clerk-coat equip) without opening CH02 / payments / Stage E.

## 2. Results

| Проверка | Режим | Результат |
|---|---|---|
| `python3 scripts/validate_ch01_expansion.py` | schema | **PASS** — 12/30/5/10 + 44 dialogues + 6 rewards |
| `smoke_ch01_expansion.gd` | mock Godot | **PASS** — SQ01–05, puzzle reset, POI journal, POI-09 idempotent reward, EX queue, `poi.tscn` |
| `smoke_ch01_expansion_live.sh` | live `:8097` | **PASS** — SQ01–05, SQ02 reset, POI-09 soft=50 once, journal, skill-up |
| `go test ./...` | unit | **PASS** — store + httpapi incl. `TestPOI09RewardIdempotent` |
| `build_debug_apk.sh` | debug | **PASS** → `build/BashLegends-debug.apk` |
| `check_release_keystore.sh` | — | **exit 2** — release keystore unavailable (ожидаемо) |

## 3. Fixes landed in this cycle

| ID | Описание |
|---|---|
| FIX-01 | Mock `ApiClient` sequence puzzle returns `puzzle_reset`; claim validates steps / idempotent `already` |
| FIX-02 | Mock + live grant for POI reward bundles (POI-09 `CH01-POI-09-FIRST`) once via `claimed_rewards` |
| FIX-03 | Full E2E smoke coverage SQ01–SQ05 + journal/EX + live shell wired into `ci_validate.sh` |
| FIX-04 | `build_debug_apk.sh` accepts Java 21 when 17 absent |

## 4. Gaps / still blocked

| Sev | ID | Описание | Статус |
|---|---|---|---|
| P2 | GAP-01 | Device install + manual POI/sidequest walkthrough not run here | **OWNER device** |
| P2 | GAP-02 | Live API URL for phones still unset (`127.0.0.1`) | T-129 |
| P3 | GAP-03 | POI-09 local 60s timer UX is client-side only; server grants on `stop_erase` without enforcing timer | Draft OK |
| P3 | GAP-04 | Battle-sim unit inject of skill/equip flats noted as follow-up in expansion doc | open |
| PX | — | CH02 / Stage E / real payments / release keystore | BLOCKED |

## 5. Verdict

**Slice E automation: DONE_VERIFIED** (paths + smokes + debug APK + this report).  
**CH01 product accept (T-128): still not accepted** — needs owner device pass.

## 6. Evidence paths

- Mock log: `/tmp/smoke_exp_godot.log`
- Live log: `/tmp/exp_live.log`
- APK: `build/BashLegends-debug.apk` (gitignored)
- Scripts: `client/scripts/tools/smoke_ch01_expansion.gd`, `scripts/smoke_ch01_expansion_live.sh`
