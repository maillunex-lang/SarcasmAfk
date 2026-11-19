# EQUIPMENT-001 — Content

## Catalog

32 templates in `client/data/equipment/equipment_catalog_v1.json` with flavor text from TZ §7.

Sets: `client/data/equipment/equipment_sets.json`.

Visual TEMP icons: `client/assets/ui/equipment/eq_icon_*.jpg` (32) + scrap material icon.  
Manifest: `client/data/equipment/equipment_visual_assets.json` (`status: temp_generated`).

## CH01 guaranteed rewards

| Trigger | Template | Bundle key |
|---------|----------|------------|
| B02 | `eq_n_starter_blade` | `CH01-B02-EQ-FIRST_CLEAR` |
| SQ02 | `eq_ch01_clerk_coat` | `CH01-SQ02-FIRST_CLEAR` |
| B07 | `eq_n_starter_charm` | `CH01-B07-EQ-FIRST_CLEAR` |
| B13 | `eq_n_blank_form` | `CH01-B13-EQ-FIRST_CLEAR` |
| B20 | `eq_r_queue_token` | `CH01-B20-EQ-FIRST_CLEAR` |
| B30 | `eq_sr_emergency_armor` | `CH01-B30-EQ-FIRST_CLEAR` |

## Dialogues

EQ-EX01..EX04 added to `ch01_expansion_dialogues.json` (do not replace Q01–Q12 mains).

## Aliases

`starter_blade` → `eq_n_starter_blade`, `starter_mail` → `eq_n_starter_mail`, `starter_charm` → `eq_n_starter_charm`.

## Validator

`python3 scripts/validate_equipment_001.py` — CI-friendly uniqueness/slots/sets/rewards check.
