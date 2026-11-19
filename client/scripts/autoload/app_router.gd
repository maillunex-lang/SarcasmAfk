class_name SceneNav
extends RefCounted
## Scene navigation for CH01 campaign stub flow.

const SCENE_SPLASH := "res://scenes/boot/splash.tscn"
const SCENE_HOME := "res://scenes/home/home.tscn"
const SCENE_CAMPAIGN := "res://scenes/campaign/campaign.tscn"
const SCENE_L01 := "res://scenes/location/l01.tscn"
const SCENE_LOCATION := "res://scenes/location/l01.tscn"
const SCENE_DIALOG := "res://scenes/dialog/dialog.tscn"
const SCENE_BATTLE := "res://scenes/battle/battle.tscn"


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
