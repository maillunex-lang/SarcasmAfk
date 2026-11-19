extends Node
## Persistent client mock state — CH01 campaign + Phase 1 MVP systems.

signal progress_changed

const SAVE_PATH := "user://bashlegends_v0_save.json"
const ROSTER_PATH := "res://data/heroes/roster_mvp.json"
const AFK_CONFIG_PATH := "res://data/afk/afk_config.json"
const EXPEDITIONS_PATH := "res://data/afk/expeditions_mvp.json"
const EVENTS_PATH := "res://data/afk/events_mvp.json"
const GACHA_PATH := "res://data/gacha/banners_mvp.json"
const CITIES_PATH := "res://data/cities/mvp_cities.json"

var soft_currency: int = 0
var hard_currency: int = 0
var summon_tickets: int = 10
var commander_xp: int = 0
var party_ids: Array = ["H01", "H04", "H02", "H03", "H07"]
var heroes_catalog: Array = []
var owned_heroes: Dictionary = {} # id -> true
var hero_levels: Dictionary = {} # id -> level
var equipment: Dictionary = {} # hero_id -> {weapon, armor, accessory}
var inventory: Dictionary = {"iron_scrap": 5, "arcane_ink": 3, "ticket_stub": 1}
var last_battle_result: Dictionary = {}

var api: ApiClient
var catalog: CampaignCatalog
var completed_quests: Dictionary = {}
var completed_battles: Dictionary = {}
var claimed_rewards: Dictionary = {}
var active_quest_id: String = ""
var active_battle_id: String = ""
var pending_dialogue_quest_id: String = ""
var prefer_live_api: bool = false
var live_api_url: String = "http://127.0.0.1:8080/v1"
var saved_auth_token: String = ""
var last_session_status: String = "mock" # mock | live | live_unreachable | token_expired

# AFK / expeditions
var afk_started_unix: int = 0
var afk_claimed_unix: int = 0
var active_expedition_id: String = ""
var expedition_ends_unix: int = 0
var cities: Array = []
var events: Array = []
var expeditions: Array = []
var gacha_banners: Array = []
var afk_config: Dictionary = {}


func _ready() -> void:
	api = ApiClient.new()
	catalog = CampaignCatalog.new()
	catalog.load_all()
	_load_content_packs()
	_load_heroes()
	_load_client_config()
	load_game()
	_apply_api_mode()
	if afk_started_unix == 0:
		afk_started_unix = int(Time.get_unix_time_from_system())
		afk_claimed_unix = afk_started_unix


func is_release_build() -> bool:
	# Godot tags release exports with "release"; editor/debug keep mock-friendly defaults.
	return OS.has_feature("release") and not OS.has_feature("editor")


func allows_mock_toggle() -> bool:
	# D-NET-05: debug/editor may switch; release stays live-oriented.
	return not is_release_build()


func _load_client_config() -> void:
	var path := "res://data/net/client_config.json"
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		var url := str(parsed.get("live_api_url", ""))
		if url != "":
			live_api_url = url


func _apply_api_mode() -> void:
	# T-114 / D-NET-05: release → live by default (no silent mock fallback on failure).
	if is_release_build():
		prefer_live_api = true
		_resume_or_probe_live()
		return
	if prefer_live_api:
		_resume_or_probe_live()
	else:
		api.configure_mock()
		last_session_status = "mock"


func _resume_or_probe_live() -> Dictionary:
	api.configure_live(live_api_url)
	# 1) Try saved token (T-123)
	if saved_auth_token != "":
		var resumed: Dictionary = api.resume_session(live_api_url, saved_auth_token)
		if bool(resumed.get("ok", false)):
			last_session_status = "live"
			_apply_server_progress(resumed.get("progress", {}))
			return resumed
		if str(resumed.get("error", "")) == "TOKEN_EXPIRED":
			last_session_status = "token_expired"
			push_warning("Live token expired; re-auth required (not falling back to mock)")
		else:
			last_session_status = "live_unreachable"
			push_warning("Live resume failed: %s" % resumed.get("error", "?"))
			# Stay live-configured; do not mock (D-NET-04)
			return resumed
	# 2) Fresh anonymous auth after probe
	var probe: Dictionary = api.probe_live(live_api_url)
	if bool(probe.get("ok", false)):
		saved_auth_token = str(probe.get("token", api.auth_token))
		last_session_status = "live"
		var prog: Dictionary = api.get_progress(null)
		if bool(prog.get("ok", false)):
			_apply_server_progress(prog.get("progress", {}))
		save_game()
		return probe
	last_session_status = "live_unreachable"
	# Keep prefer_live + live config; no silent mock
	return probe


func _apply_server_progress(progress: Dictionary) -> void:
	if typeof(progress) != TYPE_DICTIONARY or progress.is_empty():
		return
	if progress.has("soft_currency"):
		soft_currency = int(progress.get("soft_currency", soft_currency))
	if progress.has("hard_currency"):
		hard_currency = int(progress.get("hard_currency", hard_currency))
	if progress.has("commander_xp"):
		commander_xp = int(progress.get("commander_xp", commander_xp))
	if progress.has("summon_tickets"):
		summon_tickets = int(progress.get("summon_tickets", summon_tickets))
	if progress.has("party_ids"):
		party_ids = progress.get("party_ids", party_ids)
	if progress.has("claimed_rewards") and typeof(progress.get("claimed_rewards")) == TYPE_DICTIONARY:
		claimed_rewards = progress.get("claimed_rewards")
	if progress.has("quest_flags") and typeof(progress.get("quest_flags")) == TYPE_DICTIONARY:
		# Map battle:ID flags into completed_battles when present
		var qf: Dictionary = progress.get("quest_flags")
		for k in qf.keys():
			var key := str(k)
			if key.begins_with("battle:") and bool(qf[k]):
				completed_battles[key.replace("battle:", "")] = true
			elif bool(qf[k]):
				completed_quests[key] = true
	progress_changed.emit()


func set_live_api(enabled: bool, url: String = "") -> Dictionary:
	if url != "":
		live_api_url = url
	if enabled:
		var probe: Dictionary = api.probe_live(live_api_url)
		if not bool(probe.get("ok", false)):
			# D-NET-04: do not silently switch to mock; keep previous mode
			return {
				"ok": false,
				"error": str(probe.get("error", "LIVE_FAILED")),
				"live": not api.is_mock(),
				"mock": api.is_mock(),
				"detail": probe,
			}
		prefer_live_api = true
		saved_auth_token = str(probe.get("token", api.auth_token))
		last_session_status = "live"
		var prog: Dictionary = api.get_progress(null)
		if bool(prog.get("ok", false)):
			_apply_server_progress(prog.get("progress", {}))
		save_game()
		progress_changed.emit()
		return {
			"ok": true,
			"live": true,
			"mock": false,
			"token": api.auth_token,
			"base_url": api.base_url,
			"session": last_session_status,
		}
	prefer_live_api = false
	api.configure_mock()
	saved_auth_token = ""
	last_session_status = "mock"
	save_game()
	progress_changed.emit()
	return {"ok": true, "live": false, "mock": true, "base_url": api.base_url}


func _load_content_packs() -> void:
	afk_config = _read_json(AFK_CONFIG_PATH)
	var exp_data := _read_json(EXPEDITIONS_PATH)
	expeditions = exp_data.get("expeditions", [])
	var ev_data := _read_json(EVENTS_PATH)
	events = ev_data.get("events", [])
	var gacha := _read_json(GACHA_PATH)
	gacha_banners = gacha.get("banners", [])
	var city_data := _read_json(CITIES_PATH)
	cities = city_data.get("cities", [])


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


func _load_heroes() -> void:
	# Prefer local MVP roster (12 heroes); ApiClient still serves V0 path for smoke compat.
	var data := _read_json(ROSTER_PATH)
	if data.has("heroes"):
		heroes_catalog = data["heroes"]
	else:
		var res: Dictionary = api.get_heroes()
		heroes_catalog = res.get("heroes", [])
	for h in heroes_catalog:
		var id := str(h.get("id", ""))
		if bool(h.get("owned", false)):
			owned_heroes[id] = true
			hero_levels[id] = int(h.get("level", 1))
		if not equipment.has(id):
			equipment[id] = {"weapon": "", "armor": "", "accessory": ""}


func get_hero(hero_id: String) -> Dictionary:
	for h in heroes_catalog:
		if str(h.get("id", "")) == hero_id:
			return h
	return {}


func get_party() -> Array:
	var out: Array = []
	for id in party_ids:
		var h := get_hero(str(id))
		if not h.is_empty() and bool(owned_heroes.get(str(id), false)):
			out.append(h)
	return out


func set_party_slot(index: int, hero_id: String) -> bool:
	if index < 0 or index >= 5:
		return false
	if not bool(owned_heroes.get(hero_id, false)):
		return false
	# unique ids
	if party_ids.has(hero_id):
		var old_i := party_ids.find(hero_id)
		if old_i >= 0 and old_i != index:
			party_ids[old_i] = party_ids[index]
	while party_ids.size() < 5:
		party_ids.append("")
	party_ids[index] = hero_id
	save_game()
	progress_changed.emit()
	return true


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


func complete_battle(battle_id: String, server_finish: Dictionary = {}) -> Dictionary:
	var info := {"newly_completed": false, "quest_completed": false, "next_battle_id": "", "reward": {}, "server_authoritative": false}
	# Live: only apply progress if server confirmed victory (D-COMBAT-05).
	if api != null and not api.is_mock():
		info["server_authoritative"] = true
		if not bool(server_finish.get("ok", false)) or not bool(server_finish.get("victory", false)):
			info["error"] = str(server_finish.get("error", "SERVER_NO_VICTORY"))
			return info
		if is_battle_completed(battle_id):
			info["next_battle_id"] = _next_incomplete_battle()
			return info
		completed_battles[battle_id] = true
		info["newly_completed"] = true
		var srew: Dictionary = server_finish.get("reward", {})
		if typeof(srew) == TYPE_DICTIONARY and not srew.is_empty():
			soft_currency += int(srew.get("soft_delta", 0))
			commander_xp += int(srew.get("xp_delta", 0))
			var bid := str(srew.get("bundle_id", ""))
			if bid != "":
				claimed_rewards[bid] = true
			info["reward"] = srew
		var next_id := _next_incomplete_battle()
		info["next_battle_id"] = next_id
		active_battle_id = next_id
		if next_id == "":
			var qid := active_quest_id
			if qid != "" and not is_quest_completed(qid):
				completed_quests[qid] = true
				info["quest_completed"] = true
				active_quest_id = ""
				active_battle_id = ""
		progress_changed.emit()
		save_game()
		return info

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
	var next_id2 := _next_incomplete_battle()
	info["next_battle_id"] = next_id2
	active_battle_id = next_id2
	if next_id2 == "":
		var qid2 := active_quest_id
		if qid2 != "" and not is_quest_completed(qid2):
			completed_quests[qid2] = true
			var qrew_bundle := str(catalog.get_quest(qid2).get("reward_bundle_id", qid2 + "-FIRST_CLEAR"))
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


func set_battle_result(result: Dictionary) -> Dictionary:
	last_battle_result = result
	if api == null or not result.has("battle_id"):
		return {"ok": true, "skipped": true}
	var fin: Dictionary = api.finish_battle(
		str(result.get("battle_id", "")),
		bool(result.get("victory", false)),
		int(result.get("duration_ms", 1500))
	)
	last_battle_result["server_finish"] = fin
	return fin


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


func currency_line() -> String:
	return "Soft %d · Hard %d · Тикеты %d · XP %d" % [soft_currency, hard_currency, summon_tickets, commander_xp]


# --- AFK ---
func afk_elapsed_sec() -> int:
	var now := int(Time.get_unix_time_from_system())
	return maxi(0, now - afk_claimed_unix)


func afk_capped_hours() -> float:
	var max_h := float(afk_config.get("max_hours", 24))
	return minf(max_h, float(afk_elapsed_sec()) / 3600.0)


func afk_pending_reward() -> Dictionary:
	var hours := afk_capped_hours()
	var soft := int(float(afk_config.get("soft_per_hour", 120)) * hours)
	var xp := int(float(afk_config.get("xp_per_hour", 15)) * hours)
	return {"hours": hours, "soft": soft, "xp": xp, "max_hours": afk_config.get("max_hours", 24)}


func claim_afk() -> Dictionary:
	var pending := afk_pending_reward()
	var soft := int(pending.get("soft", 0))
	var xp := int(pending.get("xp", 0))
	if soft <= 0 and xp <= 0:
		return {"ok": false, "reason": "empty"}
	soft_currency += soft
	commander_xp += xp
	afk_claimed_unix = int(Time.get_unix_time_from_system())
	progress_changed.emit()
	save_game()
	return {"ok": true, "soft": soft, "xp": xp}


# --- Expeditions ---
func start_expedition(expedition_id: String) -> bool:
	if active_expedition_id != "":
		return false
	var found: Dictionary = {}
	for e in expeditions:
		if str(e.get("id", "")) == expedition_id:
			found = e
			break
	if found.is_empty():
		return false
	active_expedition_id = expedition_id
	expedition_ends_unix = int(Time.get_unix_time_from_system()) + int(found.get("duration_sec", 60))
	save_game()
	progress_changed.emit()
	return true


func claim_expedition() -> Dictionary:
	if active_expedition_id == "":
		return {"ok": false}
	var now := int(Time.get_unix_time_from_system())
	if now < expedition_ends_unix:
		return {"ok": false, "reason": "running", "left": expedition_ends_unix - now}
	var found: Dictionary = {}
	for e in expeditions:
		if str(e.get("id", "")) == active_expedition_id:
			found = e
			break
	soft_currency += int(found.get("soft", 0))
	commander_xp += int(found.get("xp", 0))
	var result := {"ok": true, "soft": found.get("soft", 0), "xp": found.get("xp", 0), "id": active_expedition_id}
	active_expedition_id = ""
	expedition_ends_unix = 0
	save_game()
	progress_changed.emit()
	return result


# --- Gacha ---
func summon_once() -> Dictionary:
	if summon_tickets <= 0:
		return {"ok": false, "error": "NO_TICKETS"}
	summon_tickets -= 1
	var pool: Array = []
	for h in heroes_catalog:
		pool.append(h)
	var pick: Dictionary = pool[randi() % pool.size()]
	var id := str(pick.get("id", ""))
	var newly := not bool(owned_heroes.get(id, false))
	owned_heroes[id] = true
	if newly:
		hero_levels[id] = 1
	else:
		soft_currency += 50 # shard convert mock
	save_game()
	progress_changed.emit()
	return {"ok": true, "hero_id": id, "name": pick.get("name", id), "rarity": pick.get("rarity", "R"), "newly_owned": newly}


# --- RPG ---
func level_up_hero(hero_id: String) -> bool:
	if not bool(owned_heroes.get(hero_id, false)):
		return false
	var cost := 100 + int(hero_levels.get(hero_id, 1)) * 40
	if soft_currency < cost:
		return false
	soft_currency -= cost
	hero_levels[hero_id] = int(hero_levels.get(hero_id, 1)) + 1
	save_game()
	progress_changed.emit()
	return true


func equip_item(hero_id: String, slot: String, item_id: String) -> bool:
	if not bool(owned_heroes.get(hero_id, false)):
		return false
	if not equipment.has(hero_id):
		equipment[hero_id] = {"weapon": "", "armor": "", "accessory": ""}
	if not equipment[hero_id].has(slot):
		return false
	if item_id != "" and int(inventory.get(item_id, 0)) <= 0 and item_id != "starter_blade":
		# allow empty unequip; starter free
		if item_id not in ["starter_blade", "starter_mail", "starter_charm"]:
			return false
	equipment[hero_id][slot] = item_id
	save_game()
	progress_changed.emit()
	return true


func save_game() -> void:
	var payload := {
		"soft_currency": soft_currency,
		"hard_currency": hard_currency,
		"summon_tickets": summon_tickets,
		"commander_xp": commander_xp,
		"party_ids": party_ids,
		"owned_heroes": owned_heroes,
		"hero_levels": hero_levels,
		"equipment": equipment,
		"inventory": inventory,
		"completed_quests": completed_quests,
		"completed_battles": completed_battles,
		"claimed_rewards": claimed_rewards,
		"active_quest_id": active_quest_id,
		"active_battle_id": active_battle_id,
		"pending_dialogue_quest_id": pending_dialogue_quest_id,
		"afk_started_unix": afk_started_unix,
		"afk_claimed_unix": afk_claimed_unix,
		"active_expedition_id": active_expedition_id,
		"expedition_ends_unix": expedition_ends_unix,
		"prefer_live_api": prefer_live_api,
		"live_api_url": live_api_url,
		"saved_auth_token": saved_auth_token if prefer_live_api else "",
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
	hard_currency = int(data.get("hard_currency", 0))
	summon_tickets = int(data.get("summon_tickets", summon_tickets))
	commander_xp = int(data.get("commander_xp", 0))
	if data.has("party_ids"):
		party_ids = data["party_ids"]
		while party_ids.size() < 5:
			party_ids.append("")
		if party_ids.size() > 5:
			party_ids = party_ids.slice(0, 5)
	owned_heroes = data.get("owned_heroes", owned_heroes)
	hero_levels = data.get("hero_levels", hero_levels)
	equipment = data.get("equipment", equipment)
	inventory = data.get("inventory", inventory)
	completed_quests = data.get("completed_quests", {})
	completed_battles = data.get("completed_battles", {})
	claimed_rewards = data.get("claimed_rewards", {})
	active_quest_id = str(data.get("active_quest_id", ""))
	active_battle_id = str(data.get("active_battle_id", ""))
	pending_dialogue_quest_id = str(data.get("pending_dialogue_quest_id", ""))
	afk_started_unix = int(data.get("afk_started_unix", afk_started_unix))
	afk_claimed_unix = int(data.get("afk_claimed_unix", afk_claimed_unix))
	active_expedition_id = str(data.get("active_expedition_id", ""))
	expedition_ends_unix = int(data.get("expedition_ends_unix", 0))
	prefer_live_api = bool(data.get("prefer_live_api", false))
	live_api_url = str(data.get("live_api_url", live_api_url))
	saved_auth_token = str(data.get("saved_auth_token", ""))
	var old_flags = data.get("quest_flags", {})
	if typeof(old_flags) == TYPE_DICTIONARY and old_flags.get("CH01-Q01", false):
		completed_quests["CH01-Q01"] = true


func reset_progress() -> void:
	soft_currency = 0
	hard_currency = 0
	summon_tickets = 10
	commander_xp = 0
	party_ids = ["H01", "H04", "H02", "H03", "H07"]
	owned_heroes = {"H01": true, "H02": true, "H03": true, "H04": true, "H07": true}
	hero_levels = {"H01": 1, "H02": 1, "H03": 1, "H04": 1, "H07": 1}
	equipment.clear()
	inventory = {"iron_scrap": 5, "arcane_ink": 3, "ticket_stub": 1}
	completed_quests.clear()
	completed_battles.clear()
	claimed_rewards.clear()
	active_quest_id = ""
	active_battle_id = ""
	pending_dialogue_quest_id = ""
	last_battle_result.clear()
	afk_started_unix = int(Time.get_unix_time_from_system())
	afk_claimed_unix = afk_started_unix
	active_expedition_id = ""
	expedition_ends_unix = 0
	prefer_live_api = false
	saved_auth_token = ""
	last_session_status = "mock"
	if api != null:
		api.configure_mock()
	save_game()
	progress_changed.emit()
