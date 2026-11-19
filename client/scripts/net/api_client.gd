class_name ApiClient
extends RefCounted
## Thin Phase 0 API façade. USE_MOCK=true → local JSON / in-memory progress (X-Mock).
## Real HTTP is stubbed; do not invent network until server exists.

const USE_MOCK := true
const BASE_URL := "https://api.example.local/v1"
const CLIENT_VERSION := "0.0.1-ch01"
const HEADER_MOCK := "X-Mock: true"

var last_log: Array = [] # recent {method, path, mock, ok}


func is_mock() -> bool:
	return USE_MOCK


func _log(method: String, path: String, ok: bool) -> void:
	var entry := {
		"method": method,
		"path": path,
		"mock": USE_MOCK,
		"ok": ok,
		"source": "local_mock" if USE_MOCK else "http",
		"header": HEADER_MOCK if USE_MOCK else "",
	}
	last_log.append(entry)
	if last_log.size() > 40:
		last_log.pop_front()
	print("[ApiClient] %s %s mock=%s ok=%s" % [method, path, USE_MOCK, ok])


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


# --- Content ---

func get_heroes() -> Dictionary:
	## GET /content/heroes
	var path := "/content/heroes"
	if not USE_MOCK:
		_log("GET", path, false)
		return _http_not_ready(path)
	var data := _read_json("res://data/heroes/roster_mvp.json")
	if not data.has("heroes"):
		data = _read_json("res://data/heroes/roster_v0.json")
	var ok: bool = data.has("heroes")
	_log("GET", path, ok)
	return {"ok": ok, "heroes": data.get("heroes", []), "mock": true}


func get_battle(battle_id: String, catalog: CampaignCatalog = null) -> Dictionary:
	## GET /content/battles/{id}
	var path := "/content/battles/%s" % battle_id
	if not USE_MOCK:
		_log("GET", path, false)
		return _http_not_ready(path)
	var battle: Dictionary = {}
	if catalog != null:
		battle = catalog.get_battle(battle_id)
	if battle.is_empty():
		battle = _read_json("res://data/battles/%s.json" % battle_id)
	var ok: bool = not battle.is_empty()
	_log("GET", path, ok)
	if not ok:
		return {"ok": false, "error": "BATTLE_NOT_FOUND", "mock": true}
	return {"ok": true, "battle": battle, "mock": true}


func get_dialogue(quest_or_dialogue_id: String, catalog: CampaignCatalog = null) -> Dictionary:
	## GET /content/dialogues/{id}
	var path := "/content/dialogues/%s" % quest_or_dialogue_id
	if not USE_MOCK:
		_log("GET", path, false)
		return _http_not_ready(path)
	var file_path := ""
	if catalog != null and str(quest_or_dialogue_id).begins_with("CH01-Q"):
		file_path = catalog.dialogue_path(quest_or_dialogue_id)
	else:
		# Accept CH01-Q01 or ch01_q01
		var id := quest_or_dialogue_id
		if id.begins_with("CH01-Q"):
			file_path = "res://data/dialogues/ch01_q%s.json" % id.replace("CH01-Q", "")
		else:
			file_path = "res://data/dialogues/%s.json" % id
	var data := _read_json(file_path)
	var ok: bool = data.has("lines")
	_log("GET", path, ok)
	if not ok:
		return {"ok": false, "error": "NOT_FOUND", "mock": true}
	return {"ok": true, "dialogue": data, "mock": true}


func get_quests(catalog: CampaignCatalog) -> Dictionary:
	## GET /content/quests (CH01 pack) — mock extension
	var path := "/content/quests"
	if not USE_MOCK:
		_log("GET", path, false)
		return _http_not_ready(path)
	var ok: bool = catalog != null and catalog.quest_list().size() > 0
	_log("GET", path, ok)
	return {
		"ok": ok,
		"chapter": catalog.chapter if catalog else {},
		"quests": catalog.quest_list() if catalog else [],
		"mock": true,
	}


# --- Progress / rewards ---

func get_progress(state: Node) -> Dictionary:
	## GET /me/progress
	var path := "/me/progress"
	if not USE_MOCK:
		_log("GET", path, false)
		return _http_not_ready(path)
	var payload := {
		"account_id": "acc_local_mock",
		"commander_xp": int(state.get("commander_xp")),
		"soft_currency": int(state.get("soft_currency")),
		"party_ids": state.get("party_ids"),
		"quest_flags": state.get("completed_quests"),
		"claimed_rewards": state.get("claimed_rewards"),
		"active_quest_id": str(state.get("active_quest_id")),
		"active_battle_id": str(state.get("active_battle_id")),
		"updated_at": Time.get_datetime_string_from_system(true),
		"mock": true,
	}
	_log("GET", path, true)
	return {"ok": true, "progress": payload, "mock": true}


func claim_reward(bundle_id: String, soft: int, xp: int, claimed_rewards: Dictionary) -> Dictionary:
	## POST /rewards/claim — idempotent
	var path := "/rewards/claim"
	if not USE_MOCK:
		_log("POST", path, false)
		return _http_not_ready(path)
	if bundle_id == "":
		_log("POST", path, false)
		return {"ok": false, "error": "VALIDATION_FAILED", "mock": true}
	if bool(claimed_rewards.get(bundle_id, false)):
		_log("POST", path, true)
		return {
			"ok": true,
			"soft_delta": 0,
			"xp_delta": 0,
			"already_claimed": true,
			"bundle_id": bundle_id,
			"mock": true,
		}
	_log("POST", path, true)
	return {
		"ok": true,
		"soft_delta": soft,
		"xp_delta": xp,
		"already_claimed": false,
		"bundle_id": bundle_id,
		"idempotency_key": "acc_local_mock:%s" % bundle_id,
		"mock": true,
	}


func start_battle(battle_id: String, party_ids: Array) -> Dictionary:
	## POST /battles/{id}/start
	var path := "/battles/%s/start" % battle_id
	if not USE_MOCK:
		_log("POST", path, false)
		return _http_not_ready(path)
	var seed := int(Time.get_unix_time_from_system()) ^ battle_id.hash()
	_log("POST", path, true)
	return {
		"ok": true,
		"battle_id": battle_id,
		"party_ids": party_ids,
		"client_seed": seed,
		"client_version": CLIENT_VERSION,
		"mock": true,
	}


func finish_battle(battle_id: String, victory: bool, duration_ms: int = 0) -> Dictionary:
	## POST /battles/{id}/finish — mock trusts client victory (server will not)
	var path := "/battles/%s/finish" % battle_id
	if not USE_MOCK:
		_log("POST", path, false)
		return _http_not_ready(path)
	_log("POST", path, true)
	return {
		"ok": true,
		"battle_id": battle_id,
		"victory": victory,
		"duration_ms": duration_ms,
		"rewards_claimed": false,
		"mock": true,
		"note": "client victory trusted only while USE_MOCK",
	}


func _http_not_ready(path: String) -> Dictionary:
	return {
		"ok": false,
		"error": "HTTP_NOT_IMPLEMENTED",
		"path": path,
		"base_url": BASE_URL,
		"mock": false,
	}
