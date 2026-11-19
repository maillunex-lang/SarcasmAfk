extends Node
## Persistent client mock state for V0-C (not server-authoritative).

signal progress_changed

const SAVE_PATH := "user://bashlegends_v0_save.json"
const HEROES_PATH := "res://data/heroes/roster_v0.json"

var soft_currency: int = 0
var commander_xp: int = 0
var quest_flags: Dictionary = {}
var claimed_rewards: Dictionary = {}
var party_ids: Array = ["H01", "H02", "H03"]
var heroes_catalog: Array = []
var last_battle_result: Dictionary = {}


func _ready() -> void:
	_load_heroes()
	load_game()


func _load_heroes() -> void:
	var file := FileAccess.open(HEROES_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing heroes roster")
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY and data.has("heroes"):
		heroes_catalog = data["heroes"]


func get_hero(hero_id: String) -> Dictionary:
	for h in heroes_catalog:
		if str(h.get("id", "")) == hero_id:
			return h
	return {}


func get_party() -> Array:
	var out: Array = []
	for id in party_ids:
		var h := get_hero(str(id))
		if not h.is_empty():
			out.append(h)
	return out


func is_quest_done(quest_id: String) -> bool:
	return bool(quest_flags.get(quest_id, false))


func mark_quest_done(quest_id: String) -> void:
	quest_flags[quest_id] = true
	progress_changed.emit()
	save_game()


func claim_reward(bundle_id: String, soft: int, xp: int) -> bool:
	if claimed_rewards.get(bundle_id, false):
		return false
	claimed_rewards[bundle_id] = true
	soft_currency += soft
	commander_xp += xp
	progress_changed.emit()
	save_game()
	return true


func set_battle_result(result: Dictionary) -> void:
	last_battle_result = result


func save_game() -> void:
	var payload := {
		"soft_currency": soft_currency,
		"commander_xp": commander_xp,
		"quest_flags": quest_flags,
		"claimed_rewards": claimed_rewards,
		"party_ids": party_ids,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	soft_currency = int(data.get("soft_currency", 0))
	commander_xp = int(data.get("commander_xp", 0))
	quest_flags = data.get("quest_flags", {})
	claimed_rewards = data.get("claimed_rewards", {})
	if data.has("party_ids"):
		party_ids = data["party_ids"]


func reset_progress() -> void:
	soft_currency = 0
	commander_xp = 0
	quest_flags.clear()
	claimed_rewards.clear()
	last_battle_result.clear()
	save_game()
	progress_changed.emit()
