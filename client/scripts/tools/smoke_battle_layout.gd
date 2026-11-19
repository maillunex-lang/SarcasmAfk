extends SceneTree
## AFK-style battle field smoke: full-bleed field + no legacy card grid.
## godot4 --headless --path client -s res://scripts/tools/smoke_battle_layout.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame

	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		push_error("FAIL GameState missing")
		quit(1)
		return
	gs.reset_progress()
	gs.active_quest_id = "CH01-Q01"
	gs.active_battle_id = "B01"
	await process_frame

	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	if packed == null:
		push_error("FAIL battle.tscn")
		quit(1)
		return
	var battle: Node = packed.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	await process_frame

	var field := battle.get_node_or_null("BattleField")
	if field == null:
		push_error("FAIL BattleField missing")
		failed = true
	else:
		print("OK BattleField")
		if field.get_child_count() < 3:
			push_error("FAIL expected standing units on field, got %s" % field.get_child_count())
			failed = true
		else:
			print("OK field units=", field.get_child_count())

	var tray := battle.get_node_or_null("BattleTray")
	if tray == null:
		push_error("FAIL BattleTray missing")
		failed = true
	else:
		print("OK BattleTray")
	var portraits := battle.find_child("PortraitTray", true, false)
	if portraits == null:
		push_error("FAIL PortraitTray missing")
		failed = true
	elif portraits.get_child_count() < 1:
		push_error("FAIL PortraitTray empty")
		failed = true
	else:
		print("OK PortraitTray count=", portraits.get_child_count())

	# Stretch mode must fill modern tall phones (no letterbox keep).
	var aspect := str(ProjectSettings.get_setting("display/window/stretch/aspect", ""))
	if aspect != "expand":
		push_error("FAIL stretch aspect=%s want expand" % aspect)
		failed = true
	else:
		print("OK stretch aspect=expand")

	battle.queue_free()
	await process_frame

	if failed:
		push_error("smoke_battle_layout FAILED")
		quit(1)
	else:
		print("smoke_battle_layout OK")
		quit(0)
