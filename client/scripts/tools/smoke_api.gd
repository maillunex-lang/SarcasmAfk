extends SceneTree
## Headless ApiClient mock smoke (Phase 0).
## godot4 --headless --path . -s res://scripts/tools/smoke_api.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame

	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		gs = load("res://scripts/autoload/game_state.gd").new()
		gs.name = "GameState"
		root.add_child(gs)
		await process_frame

	gs.reset_progress()
	var api: ApiClient = gs.api
	if api == null:
		push_error("FAIL GameState.api missing")
		quit(1)
		return

	if not api.is_mock():
		push_error("FAIL expected use_mock=true (default offline smoke)")
		failed = true
	else:
		print("OK use_mock=", api.is_mock())

	var heroes: Dictionary = api.get_heroes()
	if not bool(heroes.get("ok", false)) or heroes.get("heroes", []).size() < 12:
		push_error("FAIL get_heroes")
		failed = true
	else:
		print("OK get_heroes n=", heroes["heroes"].size())

	var battle: Dictionary = api.get_battle("B01", gs.catalog)
	if not bool(battle.get("ok", false)):
		push_error("FAIL get_battle B01")
		failed = true
	else:
		print("OK get_battle B01 enemies=", battle["battle"].get("enemies", []).size())

	var missing: Dictionary = api.get_battle("B999", gs.catalog)
	if bool(missing.get("ok", false)) or str(missing.get("error", "")) != "BATTLE_NOT_FOUND":
		push_error("FAIL expected BATTLE_NOT_FOUND")
		failed = true
	else:
		print("OK BATTLE_NOT_FOUND")

	var dlg: Dictionary = api.get_dialogue("CH01-Q01", gs.catalog)
	if not bool(dlg.get("ok", false)) or dlg.get("dialogue", {}).get("lines", []).is_empty():
		push_error("FAIL get_dialogue")
		failed = true
	else:
		print("OK get_dialogue lines=", dlg["dialogue"]["lines"].size())

	var quests: Dictionary = api.get_quests(gs.catalog)
	if not bool(quests.get("ok", false)) or quests.get("quests", []).size() != 12:
		push_error("FAIL get_quests")
		failed = true
	else:
		print("OK get_quests n=", quests["quests"].size())

	var progress: Dictionary = api.get_progress(gs)
	if not bool(progress.get("ok", false)):
		push_error("FAIL get_progress")
		failed = true
	else:
		print("OK get_progress account=", progress["progress"].get("account_id"))

	var start: Dictionary = api.start_battle("B01", gs.party_ids)
	if not bool(start.get("ok", false)) or not start.has("client_seed"):
		push_error("FAIL start_battle")
		failed = true
	else:
		print("OK start_battle seed=", start.get("client_seed"))

	var finish: Dictionary = api.finish_battle("B01", true, 1200)
	if not bool(finish.get("ok", false)) or not bool(finish.get("victory", false)):
		push_error("FAIL finish_battle")
		failed = true
	else:
		print("OK finish_battle")

	var c1: Dictionary = api.claim_reward("API-SMOKE-BUNDLE", 50, 5, gs.claimed_rewards)
	if not bool(c1.get("ok", false)) or bool(c1.get("already_claimed", true)):
		push_error("FAIL claim first")
		failed = true
	# apply like GameState
	if bool(c1.get("ok", false)) and not bool(c1.get("already_claimed", false)):
		gs.claimed_rewards["API-SMOKE-BUNDLE"] = true
		gs.soft_currency += int(c1.get("soft_delta", 0))

	var c2: Dictionary = api.claim_reward("API-SMOKE-BUNDLE", 50, 5, gs.claimed_rewards)
	if not bool(c2.get("already_claimed", false)):
		push_error("FAIL claim idempotent")
		failed = true
	else:
		print("OK claim idempotent soft=", gs.soft_currency)

	# GameState path through api
	gs.reset_progress()
	var first: bool = gs.claim_reward("GS-API-BUNDLE", 10, 1)
	var second: bool = gs.claim_reward("GS-API-BUNDLE", 10, 1)
	if not first or second:
		push_error("FAIL GameState.claim_reward via api")
		failed = true
	else:
		print("OK GameState.claim_reward via api")

	if api.last_log.is_empty():
		push_error("FAIL expected api request log")
		failed = true
	else:
		print("OK api log entries=", api.last_log.size())

	gs.reset_progress()
	quit(1 if failed else 0)
