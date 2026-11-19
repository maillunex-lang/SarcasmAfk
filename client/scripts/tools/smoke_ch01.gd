extends SceneTree
## Headless CH01 campaign data + progression smoke.
## godot4 --headless --path . -s res://scripts/tools/smoke_ch01.gd

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
	var cat = gs.catalog
	if cat == null or cat.quest_list().size() != 12:
		push_error("FAIL expected 12 quests, got %s" % (cat.quest_list().size() if cat else "null"))
		failed = true
	else:
		print("OK quests=", cat.quest_list().size())

	if cat.battles_by_id.size() != 30:
		push_error("FAIL expected 30 battles, got %s" % cat.battles_by_id.size())
		failed = true
	else:
		print("OK battles=", cat.battles_by_id.size())

	if cat.locations_by_id.size() < 10:
		push_error("FAIL expected >=10 locations, got %s" % cat.locations_by_id.size())
		failed = true
	else:
		print("OK locations=", cat.locations_by_id.size())

	# Dialogue files Q01–Q12
	for i in range(1, 13):
		var path := "res://data/dialogues/ch01_q%02d.json" % i
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_error("FAIL missing dialogue %s" % path)
			failed = true
			continue
		var data = JSON.parse_string(f.get_as_text())
		if typeof(data) != TYPE_DICTIONARY or not data.has("lines") or data["lines"].is_empty():
			push_error("FAIL dialogue structure %s" % path)
			failed = true
		else:
			print("OK dialogue ", path, " lines=", data["lines"].size())

	# Progression: Q01 available → start → clear B01+B02 → Q02 unlocks
	if not gs.is_quest_available("CH01-Q01"):
		push_error("FAIL Q01 should be available on fresh save")
		failed = true
	if gs.is_quest_available("CH01-Q02"):
		push_error("FAIL Q02 should be locked before Q01")
		failed = true

	if not gs.start_quest("CH01-Q01"):
		push_error("FAIL start_quest Q01")
		failed = true
	if gs.active_battle_id != "B01":
		push_error("FAIL expected active B01 got %s" % gs.active_battle_id)
		failed = true
	if not gs.needs_dialogue():
		push_error("FAIL dialogue pending after start")
		failed = true
	gs.mark_dialogue_seen("CH01-Q01")

	var r1: Dictionary = gs.complete_battle("B01")
	if not bool(r1.get("newly_completed", false)) or str(r1.get("next_battle_id", "")) != "B02":
		push_error("FAIL after B01 next should be B02: %s" % r1)
		failed = true
	else:
		print("OK B01 clear next=", r1.get("next_battle_id"))

	var r2: Dictionary = gs.complete_battle("B02")
	if not bool(r2.get("quest_completed", false)):
		push_error("FAIL Q01 should complete after B02: %s" % r2)
		failed = true
	else:
		print("OK Q01 completed soft=", gs.soft_currency)

	if not gs.is_quest_available("CH01-Q02"):
		push_error("FAIL Q02 should unlock after Q01")
		failed = true
	else:
		print("OK Q02 unlocked")

	# Idempotent battle complete
	var r3: Dictionary = gs.complete_battle("B01")
	if bool(r3.get("newly_completed", false)):
		push_error("FAIL B01 should not re-complete")
		failed = true

	# Spot-check a later battle loads enemies
	var b15: Dictionary = cat.get_battle("B15")
	if b15.is_empty() or b15.get("enemies", []).is_empty():
		push_error("FAIL B15 missing enemies")
		failed = true
	else:
		var engine := BattleEngine.new()
		engine.setup(gs.get_party(), b15.get("enemies", []))
		var guard := 0
		while not engine.finished and guard < 25000:
			engine.tick(0.05)
			for h in engine.heroes:
				if h.can_ultimate():
					engine.try_cast_ultimate(h.id)
			guard += 1
		if not engine.finished:
			push_error("FAIL B15 did not finish")
			failed = true
		else:
			print("OK B15 sim victory=", engine.victory, " ticks=", guard)

	# Scene loads
	for path in [
		"res://scenes/campaign/campaign.tscn",
		"res://scenes/home/home.tscn",
		"res://scenes/location/l01.tscn",
		"res://scenes/dialog/dialog.tscn",
		"res://scenes/battle/battle.tscn",
	]:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("FAIL load %s" % path)
			failed = true
			continue
		# Ensure battle has an active id for UI
		if path.ends_with("battle.tscn") and gs.active_battle_id == "":
			gs.active_battle_id = "B03"
			if not gs.is_quest_completed("CH01-Q02"):
				gs.start_quest("CH01-Q02")
		var node := packed.instantiate()
		root.add_child(node)
		await process_frame
		await process_frame
		print("OK instantiate ", path)
		node.queue_free()
		await process_frame

	gs.reset_progress()
	quit(1 if failed else 0)
