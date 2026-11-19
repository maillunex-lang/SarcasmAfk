class_name ApiClient
extends RefCounted
## Thin Phase 0/2 API façade.
## use_mock=true → local JSON / in-memory progress (X-Mock).
## use_mock=false → HTTP against Phase2 Go API (scripts/run_api.sh).

const CLIENT_VERSION := "0.0.1-ch01"
const HEADER_MOCK := "X-Mock: true"
const DEFAULT_BASE := "http://127.0.0.1:8080/v1"

## Default stays mock so headless CI smokes remain offline.
var use_mock: bool = true
var base_url: String = DEFAULT_BASE
var auth_token: String = ""
var last_log: Array = [] # recent {method, path, mock, ok}

var _host: String = "127.0.0.1"
var _port: int = 8080
var _tls: bool = false
var _prefix: String = "/v1"


func is_mock() -> bool:
	return use_mock


func configure_live(url: String = DEFAULT_BASE) -> void:
	use_mock = false
	base_url = url
	_parse_base(url)


func configure_mock() -> void:
	use_mock = true
	auth_token = ""


func set_auth_token(token: String) -> void:
	auth_token = token


## Resume existing Bearer token via GET /me/progress. Does not fall back to mock.
func resume_session(url: String = DEFAULT_BASE, token: String = "") -> Dictionary:
	if token != "":
		auth_token = token
	if auth_token == "":
		return {"ok": false, "error": "NO_TOKEN", "mock": use_mock}
	configure_live(url)
	var prog := get_progress(null)
	if bool(prog.get("ok", false)):
		return {"ok": true, "progress": prog.get("progress", {}), "token": auth_token, "resumed": true}
	var status := int(prog.get("http_status", 0))
	if status == 401 or str(prog.get("error", "")) == "UNAUTHENTICATED":
		return {"ok": false, "error": "TOKEN_EXPIRED", "detail": prog, "mock": false}
	return {"ok": false, "error": "RESUME_FAILED", "detail": prog, "mock": false}


## Probe live server (health + anonymous auth). Never silently falls back to mock (D-NET-04).
func probe_live(url: String = DEFAULT_BASE) -> Dictionary:
	var prev_mock := use_mock
	var prev_url := base_url
	var prev_token := auth_token
	configure_live(url)
	# healthz is outside /v1 prefix
	var health_path := "/healthz"
	var saved_prefix := _prefix
	_prefix = ""
	var health := _http("GET", health_path)
	_prefix = saved_prefix
	if not bool(health.get("ok", false)):
		# restore previous mode — do not force mock
		use_mock = prev_mock
		base_url = prev_url
		auth_token = prev_token
		_parse_base(prev_url)
		return {"ok": false, "error": "LIVE_UNREACHABLE", "detail": health, "mock": use_mock}
	var auth := auth_anonymous()
	if not bool(auth.get("ok", false)):
		use_mock = prev_mock
		base_url = prev_url
		auth_token = prev_token
		_parse_base(prev_url)
		return {"ok": false, "error": "LIVE_AUTH_FAILED", "detail": auth, "mock": use_mock}
	return {"ok": true, "token": auth_token, "base_url": base_url, "mock": false, "health": health}


func _parse_base(url: String) -> void:
	_tls = url.begins_with("https://")
	var rest := url
	if rest.begins_with("https://"):
		rest = rest.substr(8)
	elif rest.begins_with("http://"):
		rest = rest.substr(7)
	var slash := rest.find("/")
	var hostport := rest if slash < 0 else rest.substr(0, slash)
	_prefix = "" if slash < 0 else rest.substr(slash)
	if _prefix.ends_with("/"):
		_prefix = _prefix.substr(0, _prefix.length() - 1)
	var colon := hostport.rfind(":")
	if colon > 0:
		_host = hostport.substr(0, colon)
		_port = int(hostport.substr(colon + 1))
	else:
		_host = hostport
		_port = 443 if _tls else 80


func _log(method: String, path: String, ok: bool) -> void:
	var entry := {
		"method": method,
		"path": path,
		"mock": use_mock,
		"ok": ok,
		"source": "local_mock" if use_mock else "http",
		"header": HEADER_MOCK if use_mock else "",
	}
	last_log.append(entry)
	if last_log.size() > 40:
		last_log.pop_front()
	print("[ApiClient] %s %s mock=%s ok=%s" % [method, path, use_mock, ok])


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


func _http(method: String, path: String, body: Variant = null) -> Dictionary:
	var http := HTTPClient.new()
	var err: Error
	if _tls:
		err = http.connect_to_host(_host, _port, TLSOptions.client())
	else:
		err = http.connect_to_host(_host, _port)
	if err != OK:
		return {"ok": false, "error": "CONNECT_FAILED", "code": err, "mock": false}
	var deadline := Time.get_ticks_msec() + 8000
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		OS.delay_msec(5)
		if Time.get_ticks_msec() > deadline:
			return {"ok": false, "error": "CONNECT_TIMEOUT", "mock": false}
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"ok": false, "error": "CONNECT_STATUS_%d" % http.get_status(), "mock": false}

	var headers: PackedStringArray = ["Content-Type: application/json", "Accept: application/json"]
	if auth_token != "":
		headers.append("Authorization: Bearer %s" % auth_token)
	var payload := ""
	if body != null:
		payload = JSON.stringify(body)
	var full_path := "%s%s" % [_prefix, path]
	var verb := HTTPClient.METHOD_GET
	match method:
		"POST":
			verb = HTTPClient.METHOD_POST
		"PUT":
			verb = HTTPClient.METHOD_PUT
		"DELETE":
			verb = HTTPClient.METHOD_DELETE
		_:
			verb = HTTPClient.METHOD_GET
	err = http.request(verb, full_path, headers, payload)
	if err != OK:
		return {"ok": false, "error": "REQUEST_FAILED", "code": err, "mock": false}
	deadline = Time.get_ticks_msec() + 8000
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		OS.delay_msec(5)
		if Time.get_ticks_msec() > deadline:
			return {"ok": false, "error": "REQUEST_TIMEOUT", "mock": false}
	if http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"ok": false, "error": "BAD_STATUS_%d" % http.get_status(), "mock": false}

	var chunks := PackedByteArray()
	deadline = Time.get_ticks_msec() + 8000
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll()
		var chunk := http.read_response_body_chunk()
		if chunk.size() > 0:
			chunks.append_array(chunk)
		else:
			OS.delay_msec(2)
		if Time.get_ticks_msec() > deadline:
			break
	var code := http.get_response_code()
	http.close()
	var text := chunks.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text) if text != "" else {}
	var data: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {"raw": text}
	data["http_status"] = code
	if not data.has("ok"):
		data["ok"] = code >= 200 and code < 300
	data["mock"] = false
	return data


func auth_anonymous() -> Dictionary:
	## POST /auth/anonymous
	var path := "/auth/anonymous"
	if use_mock:
		auth_token = "tok_local_mock"
		_log("POST", path, true)
		return {"ok": true, "token": auth_token, "mock": true}
	var res := _http("POST", path)
	var ok: bool = bool(res.get("ok", false)) and str(res.get("token", "")) != ""
	if ok:
		auth_token = str(res.get("token"))
	_log("POST", path, ok)
	return res


# --- Content ---

func get_heroes() -> Dictionary:
	## GET /content/heroes
	var path := "/content/heroes"
	if not use_mock:
		var res := _http("GET", path)
		var ok: bool = bool(res.get("ok", false)) and res.get("heroes", []) is Array
		_log("GET", path, ok)
		return res
	var data := _read_json("res://data/heroes/roster_release36.json")
	if not data.has("heroes"):
		data = _read_json("res://data/heroes/roster_mvp.json")
	if not data.has("heroes"):
		data = _read_json("res://data/heroes/roster_v0.json")
	var ok_m: bool = data.has("heroes")
	_log("GET", path, ok_m)
	return {"ok": ok_m, "heroes": data.get("heroes", []), "mock": true}


func get_battle(battle_id: String, catalog: CampaignCatalog = null) -> Dictionary:
	## GET /content/battles/{id}
	var path := "/content/battles/%s" % battle_id
	if not use_mock:
		var res := _http("GET", path)
		_log("GET", path, bool(res.get("ok", false)))
		return res
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
	if not use_mock:
		var res := _http("GET", path)
		_log("GET", path, bool(res.get("ok", false)))
		return res
	var file_path := ""
	if catalog != null and str(quest_or_dialogue_id).begins_with("CH01-Q"):
		file_path = catalog.dialogue_path(quest_or_dialogue_id)
	else:
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
	## GET /content/quests (CH01 pack) — still catalog-local; server has no quests pack yet.
	var path := "/content/quests"
	if not use_mock:
		# Live mode still uses local catalog for quest list until T-085 content service expands.
		var ok_live: bool = catalog != null and catalog.quest_list().size() > 0
		_log("GET", path, ok_live)
		return {
			"ok": ok_live,
			"chapter": catalog.chapter if catalog else {},
			"quests": catalog.quest_list() if catalog else [],
			"mock": false,
			"note": "quests served from local catalog",
		}
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
	if not use_mock:
		if auth_token == "":
			var auth := auth_anonymous()
			if not bool(auth.get("ok", false)):
				_log("GET", path, false)
				return auth
		var res := _http("GET", path)
		_log("GET", path, bool(res.get("ok", false)))
		return res
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
	if not use_mock:
		if auth_token == "":
			auth_anonymous()
		var res := _http("POST", path, {
			"bundle_id": bundle_id,
			"soft": soft,
			"commander_xp": xp,
		})
		_log("POST", path, bool(res.get("ok", false)))
		return res
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
	if not use_mock:
		if auth_token == "":
			auth_anonymous()
		var res := _http("POST", path, {
			"party_ids": party_ids,
			"client_version": CLIENT_VERSION,
		})
		_log("POST", path, bool(res.get("ok", false)))
		return res
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
	## POST /battles/{id}/finish — live: server victory authoritative
	var path := "/battles/%s/finish" % battle_id
	if not use_mock:
		if auth_token == "":
			auth_anonymous()
		var res := _http("POST", path, {
			"victory": victory,
			"duration_ms": duration_ms,
			"balance_version": "2026.11.19-atb1",
		})
		_log("POST", path, bool(res.get("ok", false)))
		return res
	_log("POST", path, true)
	return {
		"ok": true,
		"battle_id": battle_id,
		"victory": victory,
		"duration_ms": duration_ms,
		"rewards_claimed": false,
		"mock": true,
		"note": "client victory trusted only while use_mock",
	}


func send_battle_command(battle_id: String, op: String, unit_id: String, at_tick: int = 0) -> Dictionary:
	var path := "/battles/%s/command" % battle_id
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "mock": true, "op": op, "unit_id": unit_id}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {"op": op, "unit_id": unit_id, "at_tick": at_tick})
	_log("POST", path, bool(res.get("ok", false)))
	return res


func put_party(party_ids: Array) -> Dictionary:
	## PUT /me/party
	var path := "/me/party"
	if use_mock:
		_log("PUT", path, true)
		return {"ok": true, "party_ids": party_ids, "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("PUT", path, {"party_ids": party_ids})
	_log("PUT", path, bool(res.get("ok", false)))
	return res


func hero_level_up(hero_id: String, levels: int = 1) -> Dictionary:
	var path := "/heroes/%s/level-up" % hero_id
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "mock": true, "hero": {"catalog_id": hero_id, "level": levels + 1}}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {"levels": levels})
	_log("POST", path, bool(res.get("ok", false)))
	return res


func hero_star_up(hero_id: String) -> Dictionary:
	var path := "/heroes/%s/star-up" % hero_id
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {})
	_log("POST", path, bool(res.get("ok", false)))
	return res


func get_heroes_owned() -> Dictionary:
	var path := "/heroes/owned"
	if use_mock:
		_log("GET", path, true)
		return {"ok": true, "heroes": [], "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("GET", path)
	_log("GET", path, bool(res.get("ok", false)))
	return res


func chat_history(channel: String, limit: int = 50) -> Dictionary:
	var path := "/chat/%s/history?limit=%d" % [channel, limit]
	if use_mock:
		_log("GET", path, true)
		return {"ok": true, "messages": [], "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("GET", path)
	_log("GET", path, bool(res.get("ok", false)))
	return res


func chat_send(channel: String, text: String, display_name: String = "") -> Dictionary:
	var path := "/chat/%s/send" % channel
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "message": {"body": text, "channel": channel}, "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {"text": text, "display_name": display_name})
	_log("POST", path, bool(res.get("ok", false)))
	return res


func guild_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var path := "/guild"
	var body := payload.duplicate()
	body["action"] = action
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "mock": true, "action": action}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, body)
	_log("POST", path, bool(res.get("ok", false)))
	return res


func get_guild() -> Dictionary:
	var path := "/guild"
	if use_mock:
		_log("GET", path, true)
		return {"ok": true, "guild": null, "list": [], "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("GET", path)
	_log("GET", path, bool(res.get("ok", false)))
	return res


func shop_catalog() -> Dictionary:
	var path := "/shop/catalog"
	if use_mock:
		var data := _read_json("res://data/shop/shop_draft.json")
		_log("GET", path, true)
		return {"ok": true, "skus": data.get("skus", []), "purchase_mode_default": "simulated", "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("GET", path)
	_log("GET", path, bool(res.get("ok", false)))
	return res


func shop_purchase(sku: String) -> Dictionary:
	var path := "/shop/purchase"
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "sku": sku, "purchase_mode": "simulated", "mock": true, "note": "TEST/SIMULATED"}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {"sku": sku})
	_log("POST", path, bool(res.get("ok", false)))
	return res


func vip_status() -> Dictionary:
	var path := "/vip/status"
	if use_mock:
		var data := _read_json("res://data/vip/vip_draft.json")
		_log("GET", path, true)
		return {"ok": true, "vip_points": 0, "vip_level": 0, "levels": data.get("levels", []), "mock": true, "status": "draft"}
	if auth_token == "":
		auth_anonymous()
	var res := _http("GET", path)
	_log("GET", path, bool(res.get("ok", false)))
	return res


func gacha_summon_banner(banner_id: String, count: int = 1) -> Dictionary:
	var path := "/gacha/summon"
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "mock": true, "banner_id": banner_id, "results": [], "tickets": 0}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {"banner_id": banner_id, "count": count})
	_log("POST", path, bool(res.get("ok", false)))
	return res


func gacha_banners() -> Dictionary:
	var path := "/gacha/banners"
	if use_mock:
		var data := _read_json("res://data/gacha/banners_approved_draft.json")
		_log("GET", path, true)
		return {"ok": true, "banners": data.get("banners", []), "mock": true}
	var res := _http("GET", path)
	_log("GET", path, bool(res.get("ok", false)))
	return res


func vip_claim_daily() -> Dictionary:
	var path := "/vip/claim-daily"
	if use_mock:
		_log("POST", path, true)
		return {"ok": true, "already": false, "granted_soft": 50, "granted_tickets": 0, "mock": true}
	if auth_token == "":
		auth_anonymous()
	var res := _http("POST", path, {})
	_log("POST", path, bool(res.get("ok", false)))
	return res
