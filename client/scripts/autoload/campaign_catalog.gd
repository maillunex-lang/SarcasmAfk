class_name CampaignCatalog
extends RefCounted
## Loads CH01 story data (quests, locations, battles, dialogues, enemies).

const QUESTS_PATH := "res://data/quests/ch01_quests.json"
const LOCATIONS_PATH := "res://data/locations/ch01_locations.json"
const BATTLES_PATH := "res://data/battles/ch01_battles.json"
const ENEMIES_PATH := "res://data/enemies/ch01_enemies.json"

var chapter: Dictionary = {}
var quests_by_id: Dictionary = {}
var locations_by_id: Dictionary = {}
var battles_by_id: Dictionary = {}
var enemies_by_id: Dictionary = {}


func load_all() -> void:
	chapter = _read_json(QUESTS_PATH)
	quests_by_id.clear()
	for q in chapter.get("quests", []):
		quests_by_id[str(q.get("quest_id", ""))] = q

	var locs = _read_json(LOCATIONS_PATH)
	locations_by_id.clear()
	for loc in locs.get("locations", []):
		locations_by_id[str(loc.get("location_id", ""))] = loc

	var battles = _read_json(BATTLES_PATH)
	battles_by_id.clear()
	for b in battles.get("battles", []):
		battles_by_id[str(b.get("battle_id", ""))] = b

	var enemies = _read_json(ENEMIES_PATH)
	enemies_by_id.clear()
	for e in enemies.get("enemies", []):
		enemies_by_id[str(e.get("id", ""))] = e


func quest_list() -> Array:
	return chapter.get("quests", [])


func get_quest(quest_id: String) -> Dictionary:
	return quests_by_id.get(quest_id, {})


func get_location(location_id: String) -> Dictionary:
	return locations_by_id.get(location_id, {})


func get_battle(battle_id: String) -> Dictionary:
	return battles_by_id.get(battle_id, {})


func dialogue_path(quest_id: String) -> String:
	# CH01-Q01 -> ch01_q01.json
	var num := quest_id.replace("CH01-Q", "")
	return "res://data/dialogues/ch01_q%s.json" % num


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing content: %s" % path)
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}
