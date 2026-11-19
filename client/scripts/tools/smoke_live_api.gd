extends SceneTree
## Headless live ApiClient smoke against local Go API.
## Requires API on 127.0.0.1:8080 (scripts/smoke_live_api.sh starts it).
## godot4 --headless --path . -s res://scripts/tools/smoke_live_api.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame

	var api := ApiClient.new()
	api.configure_live("http://127.0.0.1:8080/v1")
	if api.is_mock():
		push_error("FAIL expected live mode")
		quit(1)
		return

	var auth: Dictionary = api.auth_anonymous()
	if not bool(auth.get("ok", false)) or str(api.auth_token) == "":
		push_error("FAIL auth_anonymous %s" % auth)
		failed = true
	else:
		print("OK auth token=", api.auth_token.substr(0, 12))

	var heroes: Dictionary = api.get_heroes()
	if not bool(heroes.get("ok", false)) or heroes.get("heroes", []).size() < 3:
		push_error("FAIL live get_heroes %s" % heroes)
		failed = true
	else:
		print("OK live get_heroes n=", heroes["heroes"].size())

	var battle: Dictionary = api.get_battle("B01")
	if not bool(battle.get("ok", false)):
		push_error("FAIL live get_battle %s" % battle)
		failed = true
	else:
		print("OK live get_battle B01")

	var progress: Dictionary = api.get_progress(null)
	if not bool(progress.get("ok", false)):
		push_error("FAIL live get_progress %s" % progress)
		failed = true
	else:
		print("OK live progress account=", progress.get("progress", {}).get("account_id"))

	var start: Dictionary = api.start_battle("B01", ["H01", "H02", "H03", "H04", "H07"])
	if not bool(start.get("ok", false)) or not start.has("client_seed"):
		push_error("FAIL live start_battle %s" % start)
		failed = true
	else:
		print("OK live start_battle seed=", start.get("client_seed"))

	var finish: Dictionary = api.finish_battle("B01", true, 1500)
	if not bool(finish.get("ok", false)):
		push_error("FAIL live finish_battle %s" % finish)
		failed = true
	else:
		print("OK live finish_battle")

	var blind: Dictionary = api.finish_battle("B01", true, 100)
	if bool(blind.get("ok", false)):
		push_error("FAIL expected NO_ACTIVE_BATTLE")
		failed = true
	else:
		print("OK live blind finish rejected error=", blind.get("error"))

	var c1: Dictionary = api.claim_reward("LIVE-SMOKE-BUNDLE", 25, 3, {})
	if not bool(c1.get("ok", false)) or bool(c1.get("already_claimed", true)):
		push_error("FAIL live claim %s" % c1)
		failed = true
	var c2: Dictionary = api.claim_reward("LIVE-SMOKE-BUNDLE", 25, 3, {})
	if not bool(c2.get("already_claimed", false)):
		push_error("FAIL live claim idempotent %s" % c2)
		failed = true
	else:
		print("OK live claim idempotent")

	quit(1 if failed else 0)
