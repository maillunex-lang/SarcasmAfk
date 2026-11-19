extends SceneTree
## Headless CH01 RPG expansion E2E smoke (Slice E / T-157).
## Covers catalog integrity + mock SQ01–SQ05 + POI/journal + EX inserts + equip/skill.
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

	# --- Catalog integrity (main chain untouched) ---
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

	for ex in ["CH01-EX-01", "CH01-EX-02", "CH01-EX-03", "CH01-EX-04", "CH01-EX-05", "CH01-EX-06"]:
		var d: Dictionary = cat.get_expansion_dialogue(ex)
		if d.is_empty() or not d.has("lines"):
			push_error("FAIL missing insert %s" % ex)
			failed = true
	print("OK expansion inserts=6 dialogues=", cat.expansion_dialogues_by_id.size())

	var coat: Dictionary = cat.get_equipment("eq_ch01_clerk_coat")
	if coat.is_empty() or str(coat.get("slot", "")) != "armor":
		push_error("FAIL eq_ch01_clerk_coat")
		failed = true
	else:
		print("OK equipment clerk coat def=", coat.get("bonuses", {}))

	var sq02_reward: Dictionary = cat.get_reward_bundle("CH01-SQ02-FIRST_CLEAR")
	var eqs: Array = sq02_reward.get("equipment", [])
	if not eqs.has("eq_ch01_clerk_coat"):
		push_error("FAIL SQ02 reward missing coat")
		failed = true

	for i in range(1, 13):
		var path := "res://data/dialogues/ch01_q%02d.json" % i
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_error("FAIL missing main dialogue %s" % path)
			failed = true

	# --- Mock SQ01 any-order + idempotent claim ---
	gs.completed_quests["CH01-Q01"] = true
	var start_res: Dictionary = gs.start_sidequest("CH01-SQ01")
	if not bool(start_res.get("ok", false)):
		push_error("FAIL start SQ01 %s" % start_res)
		failed = true
	for step in ["sq01_doc_2", "sq01_doc_1", "sq01_doc_3"]:
		var ir: Dictionary = gs.interact_poi("POI-02", step)
		if not bool(ir.get("ok", false)):
			push_error("FAIL SQ01 step %s %s" % [step, ir])
			failed = true
	var claim1: Dictionary = gs.claim_sidequest("CH01-SQ01")
	if not bool(claim1.get("ok", false)):
		push_error("FAIL claim SQ01 %s" % claim1)
		failed = true
	if int(gs.inventory.get("mat_hero_exp", 0)) < 100:
		push_error("FAIL SQ01 mat grant inv=%s" % gs.inventory)
		failed = true
	else:
		print("OK mock SQ01 claim mats=", gs.inventory.get("mat_hero_exp"))
	var claim1b: Dictionary = gs.claim_sidequest("CH01-SQ01")
	if not bool(claim1b.get("already", false)):
		# mock marks claimed via claimed_rewards; second call should be already
		if not bool(gs.claimed_rewards.get("CH01-SQ01-FIRST_CLEAR", false)):
			push_error("FAIL SQ01 not marked claimed")
			failed = true
		else:
			print("OK SQ01 claim idempotent (claimed_rewards)")
	else:
		print("OK SQ01 claim already=true")

	# --- SQ02 sequence: wrong order resets, then correct order + coat ---
	gs.completed_quests["CH01-Q03"] = true
	gs.start_sidequest("CH01-SQ02")
	var bad: Dictionary = gs.interact_poi("POI-04", "sq02_seal_gold")
	if not bool(bad.get("puzzle_reset", false)):
		push_error("FAIL SQ02 wrong order should puzzle_reset got=%s" % bad)
		failed = true
	else:
		print("OK SQ02 puzzle_reset on wrong order")
	for step2 in ["sq02_seal_blue", "sq02_seal_gold", "sq02_seal_empty"]:
		var ir2: Dictionary = gs.interact_poi("POI-04", step2)
		if not bool(ir2.get("ok", false)) or bool(ir2.get("puzzle_reset", false)):
			push_error("FAIL SQ02 step %s %s" % [step2, ir2])
			failed = true
	gs.claim_sidequest("CH01-SQ02")
	if int(gs.inventory.get("eq_ch01_clerk_coat", 0)) < 1 and not _has_coat_instance(gs):
		push_error("FAIL SQ02 coat not granted inv=%s" % gs.inventory)
		failed = true
	else:
		print("OK mock SQ02 coat granted")
	if not gs.equip_item("H01", "armor", "eq_ch01_clerk_coat"):
		# equip may need instance id after EQUIPMENT-001 path
		var coat_id := _find_coat_instance(gs)
		if coat_id == "" or not gs.equip_item("H01", "armor", coat_id):
			push_error("FAIL equip clerk coat")
			failed = true
		else:
			print("OK equip clerk coat instance on H01")
	else:
		print("OK equip clerk coat on H01")

	# --- SQ03 any-order archive (no hero grant) ---
	gs.completed_quests["CH01-Q04"] = true
	gs.start_sidequest("CH01-SQ03")
	var owned_before_h03 := bool(gs.owned_heroes.get("H03", false))
	for step3 in ["sq03_record_3", "sq03_record_1", "sq03_record_2"]:
		gs.interact_poi("POI-05", step3)
	var claim3: Dictionary = gs.claim_sidequest("CH01-SQ03")
	if not bool(claim3.get("ok", false)):
		push_error("FAIL claim SQ03 %s" % claim3)
		failed = true
	if bool(gs.owned_heroes.get("H03", false)) != owned_before_h03:
		push_error("FAIL SQ03 must not auto-grant H03")
		failed = true
	else:
		print("OK SQ03 claim no H03 grant mats=", gs.inventory.get("mat_hero_exp"))

	# --- SQ04 generators ---
	gs.completed_quests["CH01-Q07"] = true
	gs.start_sidequest("CH01-SQ04")
	for step4 in ["sq04_gen_1", "sq04_gen_2", "sq04_gen_3"]:
		gs.interact_poi("POI-07", step4)
	var claim4: Dictionary = gs.claim_sidequest("CH01-SQ04")
	if not bool(claim4.get("ok", false)):
		push_error("FAIL claim SQ04 %s" % claim4)
		failed = true
	else:
		print("OK SQ04 claim soft=", gs.soft_currency)

	# --- SQ05 prep stand ---
	gs.completed_quests["CH01-Q10"] = true
	gs.start_sidequest("CH01-SQ05")
	for step5 in ["sq05_review_hero_1", "sq05_review_hero_2", "sq05_upgrade_or_train"]:
		gs.interact_poi("POI-10", step5)
	var claim5: Dictionary = gs.claim_sidequest("CH01-SQ05")
	if not bool(claim5.get("ok", false)):
		push_error("FAIL claim SQ05 %s" % claim5)
		failed = true
	else:
		print("OK SQ05 claim")

	# --- One-shot POIs + journal flags ---
	gs.interact_poi("POI-01", "read_intro")
	if not bool(gs.journal_flags.get("poi_terminal_visited", false)):
		push_error("FAIL POI-01 journal flag")
		failed = true
	gs.completed_quests["CH01-Q02"] = true
	gs.interact_poi("POI-03", "check_power")
	if not bool(gs.journal_flags.get("poi_traffic_light_seen", false)):
		push_error("FAIL POI-03 journal flag")
		failed = true
	gs.completed_quests["CH01-Q05"] = true
	gs.interact_poi("POI-06", "compare_orders")
	if not bool(gs.journal_flags.get("poi_mirror_seen", false)):
		push_error("FAIL POI-06 journal flag")
		failed = true
	gs.completed_battles["B24"] = true
	gs.completed_quests["CH01-Q09"] = true
	gs.interact_poi("POI-08", "inspect_fragment")
	if not bool(gs.journal_flags.get("journal_seal_fragment", false)):
		push_error("FAIL POI-08 seal fragment flag")
		failed = true
	else:
		print("OK POI journal flags")

	# POI-09 first reward (timer success action)
	var soft_before_poi9: int = gs.soft_currency
	var mats_before_poi9: int = int(gs.inventory.get("mat_hero_exp", 0))
	var poi9: Dictionary = gs.interact_poi("POI-09", "stop_erase")
	if not bool(poi9.get("ok", false)):
		push_error("FAIL POI-09 interact %s" % poi9)
		failed = true
	if not bool(gs.claimed_rewards.get("CH01-POI-09-FIRST", false)):
		push_error("FAIL POI-09 reward not claimed")
		failed = true
	elif gs.soft_currency < soft_before_poi9 + 50:
		push_error("FAIL POI-09 soft grant soft=%s" % gs.soft_currency)
		failed = true
	elif int(gs.inventory.get("mat_hero_exp", 0)) < mats_before_poi9 + 20:
		push_error("FAIL POI-09 mats grant")
		failed = true
	else:
		print("OK POI-09 first reward")
	# idempotent: second success must not double-grant
	var soft_mid: int = int(gs.soft_currency)
	gs.interact_poi("POI-09", "stop_erase")
	if int(gs.soft_currency) != soft_mid:
		push_error("FAIL POI-09 double grant soft=%s->%s" % [soft_mid, gs.soft_currency])
		failed = true
	else:
		print("OK POI-09 reward idempotent")

	# --- EX inserts after battles ---
	gs._maybe_queue_expansion_insert("B01", true)
	if gs.pending_expansion_dialogue_id != "CH01-EX-01":
		push_error("FAIL EX-01 queue got=%s" % gs.pending_expansion_dialogue_id)
		failed = true
	gs.pending_expansion_dialogue_id = ""
	gs._maybe_queue_expansion_insert("B20", false)
	if gs.pending_expansion_dialogue_id != "CH01-EX-04":
		push_error("FAIL EX-04 before B20 got=%s" % gs.pending_expansion_dialogue_id)
		failed = true
	else:
		print("OK EX insert queue B01/B20")
	gs._maybe_queue_expansion_insert("B30", true)
	if not bool(gs.journal_flags.get("ch01_act_complete", false)):
		push_error("FAIL EX-06 act complete flag")
		failed = true
	else:
		print("OK EX-06 ch01_act_complete")

	# --- Journal API (mock) ---
	var journal: Dictionary = gs.api.ch01_journal()
	if not bool(journal.get("ok", false)):
		push_error("FAIL journal %s" % journal)
		failed = true
	else:
		print("OK journal mock flags=", (journal.get("journal_flags", {}) as Dictionary).size())

	# --- Skill-up mock endpoint ---
	var skill: Dictionary = gs.api.hero_skill_up("H01", "ultimate")
	if not bool(skill.get("ok", false)):
		push_error("FAIL skill-up %s" % skill)
		failed = true
	else:
		print("OK skill-up mock")

	# --- Scenes ---
	var poi_scene = load("res://scenes/poi/poi.tscn")
	if poi_scene == null:
		push_error("FAIL poi.tscn missing")
		failed = true
	else:
		var node = poi_scene.instantiate()
		root.add_child(node)
		await process_frame
		node.queue_free()
		print("OK poi.tscn instantiate")

	if failed:
		push_error("smoke_ch01_expansion FAILED")
		quit(1)
	else:
		print("smoke_ch01_expansion PASSED")
		quit(0)


func _has_coat_instance(gs) -> bool:
	for k in gs.equipment_instances.keys():
		var inst: Dictionary = gs.equipment_instances[k]
		if str(inst.get("template_id", "")) in ["eq_ch01_clerk_coat", "eq_r_clerk_coat"]:
			return true
	return false


func _find_coat_instance(gs) -> String:
	for k in gs.equipment_instances.keys():
		var inst: Dictionary = gs.equipment_instances[k]
		if str(inst.get("template_id", "")) in ["eq_ch01_clerk_coat", "eq_r_clerk_coat"]:
			return str(k)
	return ""
