extends Node
## Persistent client mock state — campaign-driven (CH01).

signal progress_changed

const SAVE_PATH := "user://bashlegends_v0_save.json"

var soft_currency: int = 0
var commander_xp: int = 0
var party_ids: Array = ["H01", "H02", "H03"]
var heroes_catalog: Array = []
var last_battle_result: Dictionary = {}

var api: ApiClient
var catalog: CampaignCatalog
var completed_quests: Dictionary = {} # quest_id -> true
var completed_battles: Dictionary = {} # battle_id -> true
var claimed_rewards: Dictionary = {}
var active_quest_id: String = ""
var active_battle_id: String = ""
var pending_dialogue_quest_id: String = ""


func _ready() -> void:
	api = ApiClient.new()
	catalog = CampaignCatalog.new()
	catalog.load_all()
	_load_heroes()
	load_game()
	if active_quest_id == "" and not is_quest_completed("CH01-Q01"):
		# Fresh profile starts available at Q01
		pass


func _load_heroes() -> void:
	var res: Dictionary = api.get_heroes()
	if bool(res.get("ok", false)):
		heroes_catalog = res.get("heroes", [])
	else:
		push_error("Missing heroes roster via ApiClient")


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


func is_quest_completed(quest_id: String) -> bool:
	return bool(completed_quests.get(quest_id, false))


func is_battle_completed(battle_id: String) -> bool:
	return bool(completed_battles.get(battle_id, false))


func is_quest_available(quest_id: String) -> bool:
	var q: Dictionary = catalog.get_quest(quest_id)
	if q.is_empty():
		return false
	if is_quest_completed(quest_id):
		return false
	var req = q.get("required_quest", null)
	if req == null or str(req) == "":
		return true
	return is_quest_completed(str(req))


func quest_status(quest_id: String) -> String:
	if is_quest_completed(quest_id):
		return "completed"
	if active_quest_id == quest_id:
		return "active"
	if is_quest_available(quest_id):
		return "available"
	return "locked"


func start_quest(quest_id: String) -> bool:
	if not is_quest_available(quest_id) and active_quest_id != quest_id:
		return false
	active_quest_id = quest_id
	pending_dialogue_quest_id = quest_id
	var q: Dictionary = catalog.get_quest(quest_id)
	var battles: Array = q.get("battle_ids", [])
	active_battle_id = str(battles[0]) if not battles.is_empty() else ""
	# Skip already completed battles when resuming
	for bid in battles:
		if not is_battle_completed(str(bid)):
			active_battle_id = str(bid)
			break
	progress_changed.emit()
	save_game()
	return true


func current_quest() -> Dictionary:
	return catalog.get_quest(active_quest_id)


func current_location() -> Dictionary:
	var q := current_quest()
	return catalog.get_location(str(q.get("location_id", "")))


func mark_dialogue_seen(quest_id: String) -> void:
	if pending_dialogue_quest_id == quest_id:
		pending_dialogue_quest_id = ""
		save_game()


func needs_dialogue() -> bool:
	return pending_dialogue_quest_id != "" and pending_dialogue_quest_id == active_quest_id


func complete_battle(battle_id: String) -> Dictionary:
	## Returns reward info if newly completed.
	var info := {"newly_completed": false, "quest_completed": false, "next_battle_id": "", "reward": {}}
	if is_battle_completed(battle_id):
		info["next_battle_id"] = _next_incomplete_battle()
		return info
	completed_battles[battle_id] = true
	info["newly_completed"] = true
	var battle: Dictionary = catalog.get_battle(battle_id)
	var reward: Dictionary = battle.get("first_clear_reward", {})
	var bundle := str(reward.get("bundle_id", battle_id + "-FIRST"))
	claim_reward(bundle, int(reward.get("soft", 0)), int(reward.get("commander_xp", 0)))
	info["reward"] = reward

	var next_id := _next_incomplete_battle()
	info["next_battle_id"] = next_id
	active_battle_id = next_id
	if next_id == "":
		# all battles of active quest done
		var qid := active_quest_id
		if qid != "" and not is_quest_completed(qid):
			completed_quests[qid] = true
			var qrew_bundle := str(catalog.get_quest(qid).get("reward_bundle_id", qid + "-FIRST_CLEAR"))
			claim_reward(qrew_bundle, 300, 40)
			info["quest_completed"] = true
			active_quest_id = ""
			active_battle_id = ""
	progress_changed.emit()
	save_game()
	return info


func _next_incomplete_battle() -> String:
	var q: Dictionary = catalog.get_quest(active_quest_id)
	for bid in q.get("battle_ids", []):
		if not is_battle_completed(str(bid)):
			return str(bid)
	return ""


func claim_reward(bundle_id: String, soft: int, xp: int) -> bool:
	var res: Dictionary = api.claim_reward(bundle_id, soft, xp, claimed_rewards)
	if not bool(res.get("ok", false)):
		return false
	if bool(res.get("already_claimed", false)):
		return false
	claimed_rewards[bundle_id] = true
	soft_currency += int(res.get("soft_delta", soft))
	commander_xp += int(res.get("xp_delta", xp))
	progress_changed.emit()
	save_game()
	return true


func export_progress() -> Dictionary:
	return api.get_progress(self)


func set_battle_result(result: Dictionary) -> void:
	last_battle_result = result
	if api and result.has("battle_id"):
		api.finish_battle(str(result.get("battle_id", "")), bool(result.get("victory", false)))


# Back-compat helpers used by older UI
func is_quest_done(quest_id: String) -> bool:
	return is_quest_completed(quest_id)


func mark_quest_done(quest_id: String) -> void:
	completed_quests[quest_id] = true
	if active_quest_id == quest_id:
		active_quest_id = ""
		active_battle_id = ""
	progress_changed.emit()
	save_game()


func chapter_progress_text() -> String:
	var total := catalog.quest_list().size()
	var done := 0
	for q in catalog.quest_list():
		if is_quest_completed(str(q.get("quest_id", ""))):
			done += 1
	return "CH01: %d / %d квестов" % [done, total]


func save_game() -> void:
	var payload := {
		"soft_currency": soft_currency,
		"commander_xp": commander_xp,
		"party_ids": party_ids,
		"completed_quests": completed_quests,
		"completed_battles": completed_battles,
		"claimed_rewards": claimed_rewards,
		"active_quest_id": active_quest_id,
		"active_battle_id": active_battle_id,
		"pending_dialogue_quest_id": pending_dialogue_quest_id,
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
	if data.has("party_ids"):
		party_ids = data["party_ids"]
	completed_quests = data.get("completed_quests", {})
	completed_battles = data.get("completed_battles", {})
	claimed_rewards = data.get("claimed_rewards", {})
	active_quest_id = str(data.get("active_quest_id", ""))
	active_battle_id = str(data.get("active_battle_id", ""))
	pending_dialogue_quest_id = str(data.get("pending_dialogue_quest_id", ""))
	# migrate old single-flag save
	var old_flags = data.get("quest_flags", {})
	if typeof(old_flags) == TYPE_DICTIONARY and old_flags.get("CH01-Q01", false):
		completed_quests["CH01-Q01"] = true


func reset_progress() -> void:
	soft_currency = 0
	commander_xp = 0
	completed_quests.clear()
	completed_battles.clear()
	claimed_rewards.clear()
	active_quest_id = ""
	active_battle_id = ""
	pending_dialogue_quest_id = ""
	last_battle_result.clear()
	save_game()
	progress_changed.emit()
