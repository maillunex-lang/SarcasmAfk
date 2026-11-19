class_name CampaignCatalog
extends RefCounted
## Loads CH01 story data (quests, locations, battles, dialogues, enemies)
## plus RPG expansion packs (sidequests, POI, rewards, equipment).

const QUESTS_PATH := "res://data/quests/ch01_quests.json"
const SIDEQUESTS_PATH := "res://data/quests/ch01_sidequests.json"
const POI_PATH := "res://data/poi/ch01_poi.json"
const EXPANSION_DIALOGUES_PATH := "res://data/dialogues/ch01_expansion_dialogues.json"
const EXPANSION_REWARDS_PATH := "res://data/rewards/ch01_expansion_rewards.json"
const EQUIPMENT_PATH := "res://data/equipment/ch01_equipment.json"
const LOCATIONS_PATH := "res://data/locations/ch01_locations.json"
const BATTLES_PATH := "res://data/battles/ch01_battles.json"
const ENEMIES_PATH := "res://data/enemies/ch01_enemies.json"

var chapter: Dictionary = {}
var quests_by_id: Dictionary = {}
var sidequests_by_id: Dictionary = {}
var poi_by_id: Dictionary = {}
var expansion_dialogues_by_id: Dictionary = {}
var reward_bundles_by_id: Dictionary = {}
var equipment_by_id: Dictionary = {}
var locations_by_id: Dictionary = {}
var battles_by_id: Dictionary = {}
var enemies_by_id: Dictionary = {}


func load_all() -> void:
	chapter = _read_json(QUESTS_PATH)
	quests_by_id.clear()
	for q in chapter.get("quests", []):
		quests_by_id[str(q.get("quest_id", ""))] = q

	var side = _read_json(SIDEQUESTS_PATH)
	sidequests_by_id.clear()
	for sq in side.get("sidequests", []):
		sidequests_by_id[str(sq.get("quest_id", ""))] = sq

	var poi_root = _read_json(POI_PATH)
	poi_by_id.clear()
	for p in poi_root.get("poi", []):
		poi_by_id[str(p.get("poi_id", ""))] = p

	var dlg_root = _read_json(EXPANSION_DIALOGUES_PATH)
	expansion_dialogues_by_id.clear()
	for d in dlg_root.get("dialogues", []):
		expansion_dialogues_by_id[str(d.get("dialogue_id", ""))] = d

	var rewards_root = _read_json(EXPANSION_REWARDS_PATH)
	reward_bundles_by_id.clear()
	for b in rewards_root.get("bundles", []):
		reward_bundles_by_id[str(b.get("bundle_id", ""))] = b

	var eq_root = _read_json(EQUIPMENT_PATH)
	equipment_by_id.clear()
	for e in eq_root.get("items", []):
		equipment_by_id[str(e.get("item_id", ""))] = e

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


func sidequest_list() -> Array:
	var out: Array = []
	for k in sidequests_by_id.keys():
		out.append(sidequests_by_id[k])
	out.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	return out


func poi_list_for_location(location_id: String) -> Array:
	var out: Array = []
	for k in poi_by_id.keys():
		var p: Dictionary = poi_by_id[k]
		if str(p.get("location_id", "")) == location_id:
			out.append(p)
	out.sort_custom(func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))
	return out


func get_quest(quest_id: String) -> Dictionary:
	return quests_by_id.get(quest_id, {})


func get_sidequest(quest_id: String) -> Dictionary:
	return sidequests_by_id.get(quest_id, {})


func get_poi(poi_id: String) -> Dictionary:
	return poi_by_id.get(poi_id, {})


func get_reward_bundle(bundle_id: String) -> Dictionary:
	return reward_bundles_by_id.get(bundle_id, {})


func get_equipment(item_id: String) -> Dictionary:
	return equipment_by_id.get(item_id, {})


func get_expansion_dialogue(dialogue_id: String) -> Dictionary:
	return expansion_dialogues_by_id.get(dialogue_id, {})


func get_location(location_id: String) -> Dictionary:
	return locations_by_id.get(location_id, {})


func get_battle(battle_id: String) -> Dictionary:
	return battles_by_id.get(battle_id, {})


func dialogue_path(quest_id: String) -> String:
	# Main quests: CH01-Q01 -> ch01_q01.json
	if quest_id.begins_with("CH01-Q") and quest_id.length() <= 8:
		var num := quest_id.replace("CH01-Q", "")
		return "res://data/dialogues/ch01_q%s.json" % num
	# Expansion dialogues live in the packed JSON; callers should use get_expansion_dialogue.
	return ""


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing content: %s" % path)
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}
