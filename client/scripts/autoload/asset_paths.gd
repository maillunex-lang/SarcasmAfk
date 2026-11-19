class_name AssetPaths
extends RefCounted
## V0-B draft asset paths (jpg drafts until atlas bake).

const BG_SPLASH := "res://assets/branding/bg_splash.jpg"
const BG_HOME := "res://assets/branding/bg_home.jpg"
const LOGO := "res://assets/branding/ui_logo_wordmark.jpg"

const L01_SKY := "res://assets/locations/L01/loc_L01_sky.jpg"
const L01_FAR := "res://assets/locations/L01/loc_L01_far.jpg"
const L01_MID := "res://assets/locations/L01/loc_L01_mid.jpg"
const L01_TERMINAL := "res://assets/locations/L01/loc_L01_props_terminal.jpg"

const ARENA_FLOOR := "res://assets/arenas/ARENA-L01/arena_L01_floor.jpg"

const H01_PORTRAIT := "res://assets/characters/H01/H01_portrait.jpg"
const H01_FULL := "res://assets/characters/H01/H01_full.jpg"
const H02_PORTRAIT := "res://assets/characters/H02/H02_portrait.jpg"
const H02_FULL := "res://assets/characters/H02/H02_full.jpg"
const H03_PORTRAIT := "res://assets/characters/H03/H03_portrait.jpg"
const H03_FULL := "res://assets/characters/H03/H03_full.jpg"
const E01 := "res://assets/enemies/E01/E01_living_ticket.jpg"

const DLG_H01 := "res://assets/dialogs/dialog_portrait_H01.jpg"
const DLG_H02 := "res://assets/dialogs/dialog_portrait_H02.jpg"
const DLG_H03 := "res://assets/dialogs/dialog_portrait_H03.jpg"
const DLG_TERMINAL := "res://assets/dialogs/dialog_portrait_NPC_TERMINAL.jpg"

const ICON_HOME := "res://assets/ui/icons/ui_icon_home.jpg"
const ICON_AFK := "res://assets/ui/icons/ui_icon_afk.jpg"
const ICON_QUEST := "res://assets/ui/icons/ui_icon_quest.jpg"
const ICON_BATTLE := "res://assets/ui/icons/ui_icon_battle.jpg"
const ICON_SKIP := "res://assets/ui/icons/ui_icon_skip.jpg"
const ICON_CLOSE := "res://assets/ui/icons/ui_icon_close.jpg"


static func tex(path: String) -> Texture2D:
	var res = load(path)
	if res is Texture2D:
		return res
	push_warning("Asset missing or not Texture2D: %s" % path)
	return null


static func dialog_portrait_for(speaker_id: String) -> Texture2D:
	match speaker_id:
		"H01":
			return tex(DLG_H01)
		"H02":
			return tex(DLG_H02)
		"H03":
			return tex(DLG_H03)
		"NPC_TERMINAL":
			return tex(DLG_TERMINAL)
		_:
			return tex(DLG_TERMINAL)
