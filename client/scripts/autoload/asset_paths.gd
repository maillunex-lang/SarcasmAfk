class_name AssetPaths
extends RefCounted
## Phase 1 asset paths — Premium Clean Stylized Fantasy drafts.

const BG_SPLASH := "res://assets/branding/bg_splash.jpg"
const BG_HOME := "res://assets/branding/bg_home.jpg"
const BG_MAP := "res://assets/branding/bg_map.jpg"
const BG_AFK := "res://assets/branding/bg_afk.jpg"
const BG_GACHA := "res://assets/branding/bg_gacha.jpg"
const BG_GUILD := "res://assets/branding/bg_guild.jpg"
const BG_ARENA := "res://assets/branding/bg_arena.jpg"
const BG_CAMPAIGN := "res://assets/branding/bg_campaign.jpg"
const BG_HEROES := "res://assets/branding/bg_heroes.jpg"
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
const ICON_MAP := "res://assets/ui/icons/ui_icon_map.jpg"
const ICON_HEROES := "res://assets/ui/icons/ui_icon_heroes.jpg"
const ICON_GUILD := "res://assets/ui/icons/ui_icon_guild.jpg"
const ICON_ARENA := "res://assets/ui/icons/ui_icon_arena.jpg"
const ICON_SUMMON := "res://assets/ui/icons/ui_icon_summon.jpg"
const ICON_EVENTS := "res://assets/ui/icons/ui_icon_events.jpg"
const ICON_SETTINGS := "res://assets/ui/icons/ui_icon_settings.jpg"
const ICON_SPEED := "res://assets/ui/icons/ui_icon_speed.jpg"
const ICON_INVENTORY := "res://assets/ui/icons/ui_icon_inventory.jpg"
const ICON_EXPEDITION := "res://assets/ui/icons/ui_icon_expedition.jpg"
const ICON_SOFT := "res://assets/ui/icons/ui_icon_soft.jpg"
const ICON_HARD := "res://assets/ui/icons/ui_icon_hard.jpg"
const ICON_TICKET := "res://assets/ui/icons/ui_icon_ticket.jpg"


static func tex(path: String) -> Texture2D:
	var res = load(path)
	if res is Texture2D:
		return res
	push_warning("Asset missing or not Texture2D: %s" % path)
	return null


static func location_layer(loc_id: String, layer: String) -> String:
	return "res://assets/locations/%s/loc_%s_%s.jpg" % [loc_id, loc_id, layer]


static func arena_floor_for(loc_id: String) -> String:
	var path := "res://assets/arenas/ARENA-%s/arena_%s_floor.jpg" % [loc_id, loc_id]
	if ResourceLoader.exists(path):
		return path
	return ARENA_FLOOR


static func hero_portrait(hero_id: String) -> String:
	return "res://assets/characters/%s/%s_portrait.jpg" % [hero_id, hero_id]


static func hero_full(hero_id: String) -> String:
	return "res://assets/characters/%s/%s_full.jpg" % [hero_id, hero_id]


static func dialog_portrait_for(speaker_id: String) -> Texture2D:
	if speaker_id.begins_with("H") and speaker_id.length() <= 3:
		var path := "res://assets/dialogs/dialog_portrait_%s.jpg" % speaker_id
		var t := tex(path)
		if t:
			return t
	match speaker_id:
		"NPC_TERMINAL":
			return tex("res://assets/dialogs/dialog_portrait_NPC_TERMINAL.jpg")
		_:
			return tex("res://assets/dialogs/dialog_portrait_NPC_TERMINAL.jpg")


static func enemy_sprite_for_type(enemy_type: String) -> String:
	match enemy_type:
		"E01":
			return "res://assets/enemies/E01/E01_living_ticket.jpg"
		"E02", "E04", "E07", "E09", "E12":
			return "res://assets/enemies/E02/E02_paper_guard.jpg"
		"E03", "E11", "E14", "E17":
			return "res://assets/enemies/E03/E03_paper_golem.jpg"
		"E05", "E06", "E10", "E13", "E15", "E16":
			return "res://assets/enemies/E05/E05_sign_guard.jpg"
		"E08", "E20", "E21", "E22", "E23", "E24", "E25", "E26", "E27":
			return "res://assets/enemies/E08/E08_form_phantom.jpg"
		"E28", "E29", "E29A", "E30":
			return "res://assets/enemies/E28/E28_inspector.jpg"
		_:
			return "res://assets/enemies/E01/E01_living_ticket.jpg"
