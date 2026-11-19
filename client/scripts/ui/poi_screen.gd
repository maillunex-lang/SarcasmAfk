extends "res://scripts/ui/screen_base.gd"
## Location POI / sidequest hub for CH01 expansion.


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_CAMPAIGN)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var loc: Dictionary = GameState.current_location()
	var loc_id := str(loc.get("location_id", "L01"))
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_child(DesignTokens.make_label("Точки интереса · %s" % loc_id, 34, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(GameState.chapter_progress_text(), 18, DesignTokens.COLOR_TEXT_MUTED))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	var pois: Array = GameState.catalog.poi_list_for_location(loc_id)
	if pois.is_empty():
		list.add_child(DesignTokens.make_label("В этой локации пока нет доступных точек.", 20, DesignTokens.COLOR_TEXT_MUTED))
	for p in pois:
		list.add_child(_poi_card(p))

	# Sidequests for this location
	for sq in GameState.catalog.sidequest_list():
		if str(sq.get("location_id", "")) != loc_id:
			continue
		list.add_child(_sidequest_card(sq))

	var journal := DesignTokens.make_button("Журнал", false)
	journal.pressed.connect(func() -> void: _show_journal())
	vbox.add_child(journal)
	var back := DesignTokens.make_button("Назад к локации", false)
	back.pressed.connect(func() -> void: SceneNav.to_location(get_tree()))
	vbox.add_child(back)


func _poi_card(p: Dictionary) -> PanelContainer:
	var poi_id := str(p.get("poi_id", ""))
	var req: Variant = p.get("required_quest")
	var locked := false
	if req != null and str(req) != "" and not GameState.is_quest_completed(str(req)):
		locked = true
	for flag in p.get("required_flags", []):
		var f := str(flag)
		if f.begins_with("battle:"):
			var bid := f.substr(7)
			if not GameState.is_battle_completed(bid):
				locked = true
		elif not bool(GameState.journal_flags.get(f, false)):
			locked = true

	var st_raw: Variant = GameState.poi_progress.get(poi_id, {})
	var st: Dictionary = st_raw if typeof(st_raw) == TYPE_DICTIONARY else {}
	var state := "locked" if locked else str(st.get("state", "available"))
	if not locked and state == "locked":
		state = "available"

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.9), 14)
	)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label(
		"%s · %s [%s]" % [poi_id, str(p.get("title", "")), state],
		22,
		DesignTokens.COLOR_TEXT_IVORY,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	box.add_child(DesignTokens.make_label(
		str(p.get("description", "")),
		16,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var goal := DesignTokens.make_label(
		"Цель: %s" % str(p.get("accessibility_label", p.get("title", ""))),
		14,
		DesignTokens.COLOR_ACCENT_CYAN,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	box.add_child(goal)

	for a in p.get("actions", []):
		var aid := str(a.get("action_id", ""))
		var btn := DesignTokens.make_button(str(a.get("label", aid)), not locked)
		btn.disabled = locked
		btn.custom_minimum_size = Vector2(0, 72)
		var captured_poi := poi_id
		var captured_action := aid
		btn.pressed.connect(func() -> void: _on_action(captured_poi, captured_action))
		box.add_child(btn)
	return panel


func _sidequest_card(sq: Dictionary) -> PanelContainer:
	var qid := str(sq.get("quest_id", ""))
	var st: Dictionary = GameState.sidequest_progress.get(qid, {})
	var state := str(st.get("state", "idle"))
	var available := GameState.is_sidequest_available(qid)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_ELEVATED, 0.85), 14)
	)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label(
		"Побочный · %s · %s" % [qid, str(sq.get("title", ""))],
		22,
		DesignTokens.COLOR_ACCENT_GOLD,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	box.add_child(DesignTokens.make_label(
		str(sq.get("synopsis", "")),
		16,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var steps: Array = st.get("completed_step_ids", [])
	box.add_child(DesignTokens.make_label(
		"Шаги %d/%d · %s" % [steps.size(), sq.get("step_ids", []).size(), state],
		16,
		DesignTokens.COLOR_ACCENT_CYAN,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	if available and state != "completed" and state != "active" and state != "ready_to_claim":
		var start := DesignTokens.make_button("Взять задание", true)
		start.pressed.connect(func() -> void:
			GameState.start_sidequest(qid)
			SceneNav.to_poi(get_tree())
		)
		box.add_child(start)
	if state == "ready_to_claim" or (steps.size() >= int(sq.get("step_ids", []).size()) and state != "completed" and steps.size() > 0):
		var claim := DesignTokens.make_button("Забрать награду", true)
		claim.pressed.connect(func() -> void:
			GameState.claim_sidequest(qid)
			SceneNav.to_poi(get_tree())
		)
		box.add_child(claim)
	return panel


func _on_action(poi_id: String, action_id: String) -> void:
	var poi: Dictionary = GameState.catalog.get_poi(poi_id)
	var sq_id := str(poi.get("sidequest_id", ""))
	var puzzle_reset := false
	if sq_id != "":
		var sq: Dictionary = GameState.catalog.get_sidequest(sq_id)
		var seq: Array = sq.get("step_sequence", [])
		if not bool(sq.get("steps_any_order", true)) and not seq.is_empty():
			var step_id := ""
			for a in poi.get("actions", []):
				if str(a.get("action_id", "")) == action_id:
					step_id = str(a.get("step_id", ""))
					break
			var st: Dictionary = GameState.sidequest_progress.get(sq_id, {"sequence_buffer": []})
			var buf: Array = st.get("sequence_buffer", [])
			var expect := buf.size()
			if expect < seq.size() and str(seq[expect]) != step_id:
				puzzle_reset = true
	var res: Dictionary = GameState.api.ch01_poi_interact(poi_id, action_id)
	if puzzle_reset:
		res["puzzle_reset"] = true
	if bool(res.get("ok", false)):
		if GameState.api.is_mock():
			GameState._mock_apply_poi(poi_id, action_id, bool(res.get("puzzle_reset", false)))
			GameState.save_game()
			GameState.progress_changed.emit()
		else:
			GameState._apply_expansion_progress(res.get("progress", {}))
			GameState.save_game()
	# Show one-shot dialogue if present
	var dlg_id := str(poi.get("dialogue_id", ""))
	if dlg_id != "":
		GameState.pending_expansion_dialogue_id = dlg_id
	SceneNav.to_poi(get_tree())


func _show_journal() -> void:
	var res: Dictionary = GameState.api.ch01_journal()
	var flags: Dictionary = res.get("journal_flags", GameState.journal_flags)
	var lines: PackedStringArray = []
	for k in flags.keys():
		if bool(flags[k]):
			lines.append(str(k))
	if lines.is_empty():
		lines.append("(пусто)")
	OS.alert("Журнал:\n" + "\n".join(lines), "Сюжетный журнал")
