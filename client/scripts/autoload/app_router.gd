class_name SceneNav
extends RefCounted
## Scene navigation for Phase 1 MVP mock screens.

const SCENE_SPLASH := "res://scenes/boot/splash.tscn"
const SCENE_HOME := "res://scenes/home/home.tscn"
const SCENE_CAMPAIGN := "res://scenes/campaign/campaign.tscn"
const SCENE_L01 := "res://scenes/location/l01.tscn"
const SCENE_LOCATION := "res://scenes/location/l01.tscn"
const SCENE_DIALOG := "res://scenes/dialog/dialog.tscn"
const SCENE_BATTLE := "res://scenes/battle/battle.tscn"
const SCENE_MAP := "res://scenes/map/map.tscn"
const SCENE_HEROES := "res://scenes/heroes/heroes.tscn"
const SCENE_PARTY := "res://scenes/party/party.tscn"
const SCENE_AFK := "res://scenes/afk/afk.tscn"
const SCENE_EXPEDITION := "res://scenes/expedition/expedition.tscn"
const SCENE_EVENTS := "res://scenes/events/events.tscn"
const SCENE_GACHA := "res://scenes/gacha/gacha.tscn"
const SCENE_INVENTORY := "res://scenes/inventory/inventory.tscn"
const SCENE_GUILD := "res://scenes/guild/guild.tscn"
const SCENE_ARENA := "res://scenes/arena/arena.tscn"
const SCENE_MORE := "res://scenes/more/more.tscn"
const SCENE_HERO_DETAIL := "res://scenes/heroes/hero_detail.tscn"
const SCENE_CHAT := "res://scenes/chat/chat.tscn"
const SCENE_SHOP := "res://scenes/shop/shop.tscn"
const SCENE_VIP := "res://scenes/vip/vip.tscn"


static func go(tree: SceneTree, path: String) -> void:
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneNav failed to load scene: %s (%s)" % [path, err])


static func to_splash(tree: SceneTree) -> void:
	go(tree, SCENE_SPLASH)


static func to_home(tree: SceneTree) -> void:
	go(tree, SCENE_HOME)


static func to_campaign(tree: SceneTree) -> void:
	go(tree, SCENE_CAMPAIGN)


static func to_l01(tree: SceneTree) -> void:
	go(tree, SCENE_LOCATION)


static func to_location(tree: SceneTree) -> void:
	go(tree, SCENE_LOCATION)


static func to_dialog(tree: SceneTree) -> void:
	go(tree, SCENE_DIALOG)


static func to_battle(tree: SceneTree) -> void:
	go(tree, SCENE_BATTLE)


static func to_map(tree: SceneTree) -> void:
	go(tree, SCENE_MAP)


static func to_heroes(tree: SceneTree) -> void:
	go(tree, SCENE_HEROES)


static func to_party(tree: SceneTree) -> void:
	go(tree, SCENE_PARTY)


static func to_afk(tree: SceneTree) -> void:
	go(tree, SCENE_AFK)


static func to_expedition(tree: SceneTree) -> void:
	go(tree, SCENE_EXPEDITION)


static func to_events(tree: SceneTree) -> void:
	go(tree, SCENE_EVENTS)


static func to_gacha(tree: SceneTree) -> void:
	go(tree, SCENE_GACHA)


static func to_inventory(tree: SceneTree) -> void:
	go(tree, SCENE_INVENTORY)


static func to_guild(tree: SceneTree) -> void:
	go(tree, SCENE_GUILD)


static func to_arena(tree: SceneTree) -> void:
	go(tree, SCENE_ARENA)


static func to_more(tree: SceneTree) -> void:
	go(tree, SCENE_MORE)


static func to_hero_detail(tree: SceneTree, hero_id: String) -> void:
	GameState.set_meta("hero_detail_id", hero_id)
	go(tree, SCENE_HERO_DETAIL)


static func to_chat(tree: SceneTree) -> void:
	go(tree, SCENE_CHAT)


static func to_shop(tree: SceneTree) -> void:
	go(tree, SCENE_SHOP)


static func to_vip(tree: SceneTree) -> void:
	go(tree, SCENE_VIP)
