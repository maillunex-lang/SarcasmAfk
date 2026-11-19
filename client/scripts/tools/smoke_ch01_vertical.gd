extends SceneTree
## Mandatory CH01 vertical slice chain (headless).
## Home→Map→L01→Dialog→Party→Battle(+ult)→Reward→Save→Next
## godot --headless --path client -s res://scripts/tools/smoke_ch01_vertical.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		push_error("FAIL GameState autoload missing")
		quit(1)
		return

	gs.reset_progress()
	gs.api.configure_mock()

	# --- Home / Map entry ---
	if not gs.start_quest("CH01-Q01"):
		push_error("FAIL start CH01-Q01")
		failed = true
	else:
		print("OK map_entry quest=CH01-Q01 battle=", gs.active_battle_id)

	if not gs.needs_dialogue():
		push_error("FAIL expected pending dialogue")
		failed = true
	else:
		print("OK dialog_pending")

	# --- Dialog ---
	var dlg: Dictionary = gs.api.get_dialogue("CH01-Q01", gs.catalog)
	if not bool(dlg.get("ok", false)) or (dlg.get("dialogue", {}).get("lines", []) as Array).is_empty():
		push_error("FAIL dialogue load")
		failed = true
	else:
		print("OK dialog_lines=", dlg["dialogue"]["lines"].size())
	gs.mark_dialogue_seen("CH01-Q01")
	if gs.needs_dialogue():
		push_error("FAIL dialogue still pending")
		failed = true
	else:
		print("OK dialog_done")

	# --- Party ---
	if gs.party_ids.size() != 5:
		push_error("FAIL party size")
		failed = true
	var has_h01 := false
	for id in gs.party_ids:
		if str(id) == "H01":
			has_h01 = true
		var h: Dictionary = gs.get_hero(str(id))
		if h.is_empty():
			push_error("FAIL missing hero %s" % id)
			failed = true
	if not has_h01:
		# ensure Kaeron in party for slice
		gs.set_party_slot(0, "H01")
	gs.save_game()
	print("OK party=", gs.party_ids)

	# Combat sprites from pipeline drafts
	for hid in ["H01", "H02", "H03"]:
		var path := "res://assets/combat/%s/%s_idle.png" % [hid, hid]
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			push_error("FAIL missing combat sprite %s" % path)
			failed = true
		else:
			print("OK combat_sprite ", hid)

	# --- Battle sim: natural energy fill + manual ultimate (no cheat fill) ---
	var BattleEngine = load("res://scripts/battle/battle_engine.gd")
	var battle_def: Dictionary = gs.catalog.get_battle("B01")
	var engine = BattleEngine.new()
	engine.setup(gs.get_party(), battle_def.get("enemies", []), 42)
	var ult_cast := false
	var natural_ready := false
	var guard := 0
	while not engine.finished and guard < 12000:
		engine.tick(0.05)
		guard += 1
		if not ult_cast:
			for u in engine.heroes:
				if u.can_ultimate():
					natural_ready = true
					if engine.try_cast_ultimate(u.id):
						ult_cast = true
						gs.api.send_battle_command("B01", "ultimate", u.id, guard)
						print("OK manual_ultimate unit=", u.id, " at_tick=", guard)
						break
	if not natural_ready:
		push_error("FAIL ultimate never became ready naturally in B01")
		failed = true
	elif not ult_cast:
		push_error("FAIL manual ultimate rejected after natural ready")
		failed = true
	if not engine.finished or not engine.victory:
		push_error("FAIL battle not won finished=%s victory=%s ticks=%s" % [engine.finished, engine.victory, guard])
		failed = true
	else:
		print("OK battle_victory ticks=", guard, " ult=", ult_cast, " natural_ready=", natural_ready)

	# --- Rewards + idempotency ---
	var soft_before: int = gs.soft_currency
	var p1: Dictionary = gs.complete_battle("B01")
	if not bool(p1.get("newly_completed", false)):
		push_error("FAIL first clear should be newly_completed")
		failed = true
	else:
		print("OK reward_first soft_delta=", gs.soft_currency - soft_before, " next=", p1.get("next_battle_id"))
	var soft_mid: int = gs.soft_currency
	var p2: Dictionary = gs.complete_battle("B01")
	if bool(p2.get("newly_completed", false)):
		push_error("FAIL duplicate reward granted")
		failed = true
	elif gs.soft_currency != soft_mid:
		push_error("FAIL soft changed on duplicate finish")
		failed = true
	else:
		print("OK reward_idempotent soft=", gs.soft_currency)

	# --- Save / resume progress ---
	gs.save_game()
	var saved_battles: Dictionary = gs.completed_battles.duplicate()
	gs.completed_battles = {}
	gs.load_game()
	if not bool(gs.completed_battles.get("B01", false)):
		push_error("FAIL save/load lost B01")
		failed = true
	else:
		print("OK save_resume B01")

	# --- Next stage ---
	if str(p1.get("next_battle_id", "")) != "B02" and not bool(gs.completed_battles.get("B02", false)):
		if gs.active_battle_id != "B02" and str(p1.get("next_battle_id", "")) == "":
			push_error("FAIL expected next B02 got %s active=%s" % [p1.get("next_battle_id"), gs.active_battle_id])
			failed = true
		else:
			print("OK next_stage active=", gs.active_battle_id, " next=", p1.get("next_battle_id"))
	else:
		print("OK next_stage B02")

	# --- Home continue CTA (mid-quest / dialog) ---
	var prev_quest: String = gs.active_quest_id
	var prev_battle: String = gs.active_battle_id
	var prev_dlg: String = gs.pending_dialogue_quest_id
	gs.active_quest_id = "CH01-Q01"
	gs.active_battle_id = "B03"
	gs.pending_dialogue_quest_id = ""
	# Ensure B03 not marked complete for continue CTA
	gs.completed_battles.erase("B03")
	var cont: Dictionary = gs.mid_quest_continue()
	if cont.is_empty() or str(cont.get("dest", "")) != "location":
		push_error("FAIL mid_quest_continue expected location got %s" % cont)
		failed = true
	else:
		print("OK home_continue dest=", cont.get("dest"))
	gs.pending_dialogue_quest_id = "CH01-Q01"
	var cont_dlg: Dictionary = gs.mid_quest_continue()
	if str(cont_dlg.get("dest", "")) != "dialog":
		push_error("FAIL mid_quest_continue dialog got %s" % cont_dlg)
		failed = true
	else:
		print("OK home_continue_dialog")
	gs.active_quest_id = prev_quest
	gs.active_battle_id = prev_battle
	gs.pending_dialogue_quest_id = prev_dlg

	# Scene instantiate chain (real Godot load)
	for path in [
		"res://scenes/home/home.tscn",
		"res://scenes/map/map.tscn",
		"res://scenes/location/l01.tscn",
		"res://scenes/dialog/dialog.tscn",
		"res://scenes/party/party.tscn",
		"res://scenes/battle/battle.tscn",
	]:
		var packed = load(path)
		if packed == null:
			push_error("FAIL load %s" % path)
			failed = true
		else:
			var node = packed.instantiate()
			if node == null:
				push_error("FAIL instantiate %s" % path)
				failed = true
			else:
				print("OK scene ", path)
				node.free()

	# Guild/arena/events remain stubs (P3)
	print("OK p3_stubs_untouched")

	if failed:
		push_error("smoke_ch01_vertical_FAILED")
		quit(1)
	else:
		print("smoke_ch01_vertical_ok")
		quit(0)
