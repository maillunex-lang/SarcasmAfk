extends SceneTree

## Headless smoke for V0-A scenes.
## godot4 --headless --path . -s res://scripts/tools/smoke_v0a.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenes := [
		"res://scenes/boot/splash.tscn",
		"res://scenes/home/home.tscn",
		"res://scenes/location/l01.tscn",
		"res://scenes/dialog/dialog.tscn",
		"res://scenes/battle/battle.tscn",
	]
	var failed := false
	for path in scenes:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("FAIL load: %s" % path)
			failed = true
			continue
		var node := packed.instantiate()
		if node == null:
			push_error("FAIL instantiate: %s" % path)
			failed = true
			continue
		root.add_child(node)
		await process_frame
		await process_frame
		if node.get_child_count() == 0:
			push_error("FAIL empty UI tree after _ready: %s" % path)
			failed = true
		else:
			print("OK ", path, " children=", node.get_child_count())
		node.queue_free()
		await process_frame

	var dialogue := FileAccess.open("res://data/dialogues/ch01_q01.json", FileAccess.READ)
	if dialogue == null:
		push_error("FAIL dialogue json missing")
		failed = true
	else:
		var data = JSON.parse_string(dialogue.get_as_text())
		if typeof(data) != TYPE_DICTIONARY or not data.has("lines") or data["lines"].size() != 10:
			push_error("FAIL dialogue json structure")
			failed = true
		else:
			print("OK dialogue lines=", data["lines"].size())

	# Title checks on splash/home via fresh instantiate
	var splash = (load("res://scenes/boot/splash.tscn") as PackedScene).instantiate()
	root.add_child(splash)
	await process_frame
	var splash_text := _collect_labels(splash)
	if splash_text.find("БашЛегенды") == -1:
		push_error("FAIL splash missing display title")
		failed = true
	else:
		print("OK splash title present")
	splash.queue_free()
	await process_frame

	quit(1 if failed else 0)


func _collect_labels(node: Node) -> String:
	var out := ""
	if node is Label:
		out += (node as Label).text + "\n"
	for child in node.get_children():
		out += _collect_labels(child)
	return out
