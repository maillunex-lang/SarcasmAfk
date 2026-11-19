extends SceneTree
## Guard: location parallax must not cover fight/dialog buttons (z-order).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		gs = load("res://scripts/autoload/game_state.gd").new()
		gs.name = "GameState"
		root.add_child(gs)
		await process_frame
	gs.active_quest_id = "CH01-Q01"
	gs.active_battle_id = "B01"
	gs.pending_dialogue_quest_id = ""

	var packed: PackedScene = load("res://scenes/location/l01.tscn")
	var node: Node = packed.instantiate()
	root.add_child(node)
	await process_frame
	await process_frame

	var layers := node.get_node_or_null("LocationLayers")
	if layers == null:
		push_error("FAIL LocationLayers missing")
		quit(1)
		return
	if int(layers.z_index) >= 0:
		push_error("FAIL LocationLayers z_index=%s must be < 0" % layers.z_index)
		quit(1)
		return

	var ui_above := false
	for child in node.get_children():
		if child is MarginContainer and int(child.z_index) > int(layers.z_index):
			ui_above = true

	var battle_btns := _count_buttons(node, "В бой")
	if not ui_above:
		push_error("FAIL UI not above location layers")
		quit(1)
		return
	if battle_btns < 1:
		push_error("FAIL battle button missing on location hub")
		quit(1)
		return

	print("OK location_ui z_layers=", layers.z_index, " battle_btn=", battle_btns)
	print("smoke_location_ui PASSED")
	quit(0)


func _count_buttons(n: Node, needle: String) -> int:
	var c := 0
	if n is Button and str((n as Button).text).findn(needle) >= 0:
		c += 1
	for ch in n.get_children():
		c += _count_buttons(ch, needle)
	return c
