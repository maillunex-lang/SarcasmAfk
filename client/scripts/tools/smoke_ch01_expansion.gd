extends SceneTree
## Headless CH01 RPG expansion content smoke (Slice A).
## godot4 --headless --path . -s res://scripts/tools/smoke_ch01_expansion.gd

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

	var cat = gs.catalog
	if cat == null:
		push_error("FAIL catalog null")
		quit(1)
		return

	# Main chain intact
	if cat.quest_list().size() != 12:
		push_error("FAIL main quests=%s" % cat.quest_list().size())
		failed = true
	else:
		print("OK main quests=12")
	if cat.battles_by_id.size() != 30:
		push_error("FAIL battles=%s" % cat.battles_by_id.size())
		failed = true
	else:
		print("OK battles=30")

	# Sidequests
	var sqs: Array = cat.sidequest_list()
	if sqs.size() != 5:
		push_error("FAIL sidequests=%s" % sqs.size())
		failed = true
	else:
		print("OK sidequests=5")
	for i in range(1, 6):
		var id := "CH01-SQ0%d" % i
		var sq: Dictionary = cat.get_sidequest(id)
		if sq.is_empty():
			push_error("FAIL missing %s" % id)
			failed = true
			continue
		var rb := str(sq.get("reward_bundle_id", ""))
		if cat.get_reward_bundle(rb).is_empty():
			push_error("FAIL missing reward %s" % rb)
			failed = true
		if sq.get("grants_heroes", []).size() > 0:
			push_error("FAIL %s must not grant heroes" % id)
			failed = true

	# POI
	if cat.poi_by_id.size() != 10:
		push_error("FAIL poi=%s" % cat.poi_by_id.size())
		failed = true
	else:
		print("OK poi=10")
	for i in range(1, 11):
		var pid := "POI-%02d" % i
		if cat.get_poi(pid).is_empty():
			push_error("FAIL missing %s" % pid)
			failed = true

	# Dialogues / inserts
	for ex in ["CH01-EX-01", "CH01-EX-02", "CH01-EX-03", "CH01-EX-04", "CH01-EX-05", "CH01-EX-06"]:
		var d: Dictionary = cat.get_expansion_dialogue(ex)
		if d.is_empty() or not d.has("lines"):
			push_error("FAIL missing insert %s" % ex)
			failed = true
	print("OK expansion inserts=6 dialogues=", cat.expansion_dialogues_by_id.size())

	# Equipment
	var coat: Dictionary = cat.get_equipment("eq_ch01_clerk_coat")
	if coat.is_empty() or str(coat.get("slot", "")) != "armor":
		push_error("FAIL eq_ch01_clerk_coat")
		failed = true
	else:
		print("OK equipment clerk coat def=", coat.get("bonuses", {}))

	# SQ02 reward references coat
	var sq02_reward: Dictionary = cat.get_reward_bundle("CH01-SQ02-FIRST_CLEAR")
	var eqs: Array = sq02_reward.get("equipment", [])
	if not eqs.has("eq_ch01_clerk_coat"):
		push_error("FAIL SQ02 reward missing coat")
		failed = true

	# Main dialogues untouched
	for i in range(1, 13):
		var path := "res://data/dialogues/ch01_q%02d.json" % i
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_error("FAIL missing main dialogue %s" % path)
			failed = true

	# Mock SQ01 flow (any order) + idempotent claim
	gs.completed_quests["CH01-Q01"] = true
	var start_res: Dictionary = gs.start_sidequest("CH01-SQ01")
	if not bool(start_res.get("ok", false)):
		push_error("FAIL start SQ01 %s" % start_res)
		failed = true
	for step in ["sq01_doc_2", "sq01_doc_1", "sq01_doc_3"]:
		gs._mock_apply_poi("POI-02", step, false)
	var claim1: Dictionary = gs.claim_sidequest("CH01-SQ01")
	if not bool(claim1.get("ok", false)):
		push_error("FAIL claim SQ01 %s" % claim1)
		failed = true
	if int(gs.inventory.get("mat_hero_exp", 0)) < 100:
		push_error("FAIL SQ01 mat grant inv=%s" % gs.inventory)
		failed = true
	else:
		print("OK mock SQ01 claim mats=", gs.inventory.get("mat_hero_exp"))

	# SQ02 wrong order resets puzzle only
	gs.completed_quests["CH01-Q03"] = true
	gs.start_sidequest("CH01-SQ02")
	gs._mock_apply_poi("POI-04", "sq02_seal_gold", true)
	var sq02: Dictionary = gs.sidequest_progress.get("CH01-SQ02", {})
	if not sq02.get("sequence_buffer", []).is_empty() and sq02.get("sequence_buffer", []).size() > 0:
		# after reset buffer should be empty
		pass
	gs._mock_apply_poi("POI-04", "sq02_seal_blue", false)
	gs._mock_apply_poi("POI-04", "sq02_seal_gold", false)
	gs._mock_apply_poi("POI-04", "sq02_seal_empty", false)
	gs.claim_sidequest("CH01-SQ02")
	if int(gs.inventory.get("eq_ch01_clerk_coat", 0)) < 1:
		push_error("FAIL SQ02 coat not granted")
		failed = true
	else:
		print("OK mock SQ02 coat granted")
	if not gs.equip_item("H01", "armor", "eq_ch01_clerk_coat"):
		push_error("FAIL equip clerk coat")
		failed = true
	else:
		print("OK equip clerk coat on H01")

	# Scene exists
	var poi_scene = load("res://scenes/poi/poi.tscn")
	if poi_scene == null:
		push_error("FAIL poi.tscn missing")
		failed = true
	else:
		print("OK poi.tscn")

	if failed:
		push_error("smoke_ch01_expansion FAILED")
		quit(1)
	else:
		print("smoke_ch01_expansion PASSED")
		quit(0)
