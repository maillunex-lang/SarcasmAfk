extends SceneTree
## Battle layout smoke: restored archive card-row battle + stretch expand.
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

	# Restored archive layout: unit cards + combat log (not AFK L/R field).
	if battle.get_node_or_null("BattleField") != null:
		push_error("FAIL unexpected BattleField (AFK shell should be reverted)")
		failed = true
	else:
		print("OK no BattleField")

	if battle.get_node_or_null("BattleTray") != null:
		push_error("FAIL unexpected BattleTray")
		failed = true
	else:
		print("OK no BattleTray")

	var logs: Array = battle.find_children("*", "RichTextLabel", true, false)
	if logs.is_empty():
		push_error("FAIL combat RichTextLabel log missing")
		failed = true
	else:
		print("OK combat log")

	var unit_bars := battle.find_children("*", "ProgressBar", true, false).size()
	if unit_bars < 3:
		push_error("FAIL expected unit HP bars on cards, got %s" % unit_bars)
		failed = true
	else:
		print("OK unit hp bars=", unit_bars)

	# Keep fullscreen expand (letterbox fix from #31); layout itself is archive rows.
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
