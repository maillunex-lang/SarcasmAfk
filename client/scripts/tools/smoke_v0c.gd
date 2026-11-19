extends SceneTree
## Headless gameplay smoke for V0-C battle engine.
## godot4 --headless --path . -s res://scripts/tools/smoke_v0c.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame

	var heroes_file := FileAccess.open("res://data/heroes/roster_v0.json", FileAccess.READ)
	var battle_file := FileAccess.open("res://data/battles/B01.json", FileAccess.READ)
	if heroes_file == null or battle_file == null:
		push_error("FAIL missing data files")
		quit(1)
		return

	var heroes_data = JSON.parse_string(heroes_file.get_as_text())
	var battle_data = JSON.parse_string(battle_file.get_as_text())
	var party: Array = heroes_data["heroes"]
	var enemies: Array = battle_data["enemies"]

	var engine := BattleEngine.new()
	engine.setup(party, enemies)

	var guard := 0
	while not engine.finished and guard < 20000:
		engine.tick(0.05)
		for h in engine.heroes:
			if h.can_ultimate():
				engine.try_cast_ultimate(h.id)
		guard += 1

	if not engine.finished or not engine.victory:
		push_error("FAIL expected finished victory on B01 (ticks=%s victory=%s)" % [guard, engine.victory])
		failed = true
	else:
		print("OK battle victory ticks=", guard)

	if Engine.has_singleton("GameState") or root.has_node("GameState") or root.get_node_or_null("/root/GameState") != null:
		var gs = root.get_node("/root/GameState")
		gs.reset_progress()
		var first: bool = gs.claim_reward("SMOKE-BUNDLE", 100, 10)
		var second: bool = gs.claim_reward("SMOKE-BUNDLE", 100, 10)
		if not first or second:
			push_error("FAIL reward idempotency")
			failed = true
		else:
			print("OK reward idempotency soft=", gs.soft_currency)
	else:
		# Fallback without autoload
		var gs2 = load("res://scripts/autoload/game_state.gd").new()
		root.add_child(gs2)
		await process_frame
		gs2.reset_progress()
		var first2: bool = gs2.claim_reward("SMOKE-BUNDLE", 100, 10)
		var second2: bool = gs2.claim_reward("SMOKE-BUNDLE", 100, 10)
		if not first2 or second2:
			push_error("FAIL reward idempotency (fallback)")
			failed = true
		else:
			print("OK reward idempotency fallback soft=", gs2.soft_currency)

	for path in [
		"res://scenes/boot/splash.tscn",
		"res://scenes/home/home.tscn",
		"res://scenes/location/l01.tscn",
		"res://scenes/dialog/dialog.tscn",
		"res://scenes/battle/battle.tscn",
	]:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("FAIL load %s" % path)
			failed = true
		else:
			var node := packed.instantiate()
			root.add_child(node)
			await process_frame
			await process_frame
			print("OK instantiate ", path)
			node.queue_free()
			await process_frame

	quit(1 if failed else 0)
