extends SceneTree
## Phase 1 MVP smoke: screens + systems (AFK/gacha/party5/roster12).
## godot4 --headless --path . -s res://scripts/tools/smoke_mvp.gd

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

	if gs.heroes_catalog.size() != 12:
		push_error("FAIL roster size %s" % gs.heroes_catalog.size())
		failed = true
	else:
		print("OK roster12")

	if gs.get_party().size() != 5:
		push_error("FAIL party size %s" % gs.get_party().size())
		failed = true
	else:
		var fronts := 0
		var backs := 0
		for h in gs.get_party():
			if str(h.get("row", "")) == "front":
				fronts += 1
			else:
				backs += 1
		print("OK party5 front=", fronts, " back=", backs)

	# AFK
	gs.afk_claimed_unix = int(Time.get_unix_time_from_system()) - 7200
	var afk: Dictionary = gs.claim_afk()
	if not bool(afk.get("ok", false)) or int(afk.get("soft", 0)) <= 0:
		push_error("FAIL afk claim %s" % afk)
		failed = true
	else:
		print("OK afk soft=", afk.get("soft"))

	# Expedition short
	if not gs.start_expedition("EX01"):
		push_error("FAIL start expedition")
		failed = true
	gs.expedition_ends_unix = int(Time.get_unix_time_from_system()) - 1
	var ex: Dictionary = gs.claim_expedition()
	if not bool(ex.get("ok", false)):
		push_error("FAIL claim expedition")
		failed = true
	else:
		print("OK expedition")

	# Gacha
	var tickets_before: int = gs.summon_tickets
	var pull: Dictionary = gs.summon_once()
	if not bool(pull.get("ok", false)) or gs.summon_tickets != tickets_before - 1:
		push_error("FAIL gacha %s" % pull)
		failed = true
	else:
		print("OK gacha ", pull.get("hero_id"))

	# Equip + level
	if not gs.equip_item("H01", "weapon", "starter_blade"):
		push_error("FAIL equip")
		failed = true
	gs.soft_currency += 500
	if not gs.level_up_hero("H01"):
		push_error("FAIL level up")
		failed = true
	else:
		print("OK rpg level=", gs.hero_levels.get("H01"))

	# Battle with 5
	var battle: Dictionary = gs.catalog.get_battle("B01")
	var engine := BattleEngine.new()
	engine.setup(gs.get_party(), battle.get("enemies", []))
	if engine.heroes.size() != 5:
		push_error("FAIL engine heroes %s" % engine.heroes.size())
		failed = true
	var guard := 0
	while not engine.finished and guard < 30000:
		engine.tick(0.05)
		for h in engine.heroes:
			if h.can_ultimate():
				engine.try_cast_ultimate(h.id)
		guard += 1
	if not engine.finished:
		push_error("FAIL 5v battle timeout")
		failed = true
	else:
		print("OK battle5 victory=", engine.victory, " ticks=", guard)

	if gs.cities.size() < 3:
		push_error("FAIL cities")
		failed = true
	else:
		print("OK cities=", gs.cities.size())

	var scenes := [
		"res://scenes/home/home.tscn",
		"res://scenes/map/map.tscn",
		"res://scenes/heroes/heroes.tscn",
		"res://scenes/party/party.tscn",
		"res://scenes/afk/afk.tscn",
		"res://scenes/expedition/expedition.tscn",
		"res://scenes/events/events.tscn",
		"res://scenes/gacha/gacha.tscn",
		"res://scenes/inventory/inventory.tscn",
		"res://scenes/guild/guild.tscn",
		"res://scenes/arena/arena.tscn",
		"res://scenes/more/more.tscn",
		"res://scenes/campaign/campaign.tscn",
	]
	for path in scenes:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("FAIL load %s" % path)
			failed = true
			continue
		var node := packed.instantiate()
		root.add_child(node)
		await process_frame
		await process_frame
		print("OK instantiate ", path)
		node.queue_free()
		await process_frame

	gs.reset_progress()
	quit(1 if failed else 0)
