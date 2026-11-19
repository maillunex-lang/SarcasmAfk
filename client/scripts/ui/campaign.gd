extends "res://scripts/ui/screen_base.gd"
## CH01 quest list — availability gated by required_quest.


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.BG_CAMPAIGN)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Кампания · CH01", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(
		"%s — %s" % [
			str(GameState.catalog.chapter.get("title", "Уфа")),
			GameState.chapter_progress_text(),
		],
		24,
		DesignTokens.COLOR_TEXT_MUTED
	))
	vbox.add_child(DesignTokens.make_label(
		"Soft: %d   ·   XP: %d" % [GameState.soft_currency, GameState.commander_xp],
		22,
		DesignTokens.COLOR_ACCENT_CYAN
	))
	vbox.add_child(DesignTokens.make_label(
		"CH02+ закрыт для игроков до прохождения CH01 (D-SCOPE-02)",
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))
	var poi_btn := DesignTokens.make_button("Точки интереса / побочные", true)
	poi_btn.pressed.connect(func() -> void: SceneNav.to_poi(get_tree()))
	vbox.add_child(poi_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	for q in GameState.catalog.quest_list():
		list.add_child(_make_quest_row(q))

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(pad)
	HubChrome.attach(self, get_tree(), "campaign")


func _make_quest_row(q: Dictionary) -> PanelContainer:
	var quest_id := str(q.get("quest_id", ""))
	var status := GameState.quest_status(quest_id)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.9), 16))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.texture = AssetPaths.tex(AssetPaths.ICON_QUEST)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)

	var title := "%s · %s" % [quest_id, str(q.get("title", ""))]
	text_box.add_child(DesignTokens.make_label(title, 26, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))

	var battles: Array = q.get("battle_ids", [])
	var done_b := 0
	for bid in battles:
		if GameState.is_battle_completed(str(bid)):
			done_b += 1
	var status_color := DesignTokens.COLOR_TEXT_MUTED
	var status_ru := "Закрыт"
	match status:
		"completed":
			status_ru = "Завершён"
			status_color = DesignTokens.COLOR_SUCCESS_MINT
		"active":
			status_ru = "В процессе · бой %s" % GameState.active_battle_id
			status_color = DesignTokens.COLOR_ACCENT_CYAN
		"available":
			status_ru = "Доступен"
			status_color = DesignTokens.COLOR_ACCENT_GOLD
		_:
			status_ru = "Закрыт"
			status_color = DesignTokens.COLOR_TEXT_MUTED
	text_box.add_child(DesignTokens.make_label(
		"%s · бои %d/%d · %s" % [status_ru, done_b, battles.size(), str(q.get("location_id", ""))],
		20,
		status_color,
		HORIZONTAL_ALIGNMENT_LEFT
	))

	var action := DesignTokens.make_button(_action_label(status), status == "available" or status == "active")
	action.disabled = status == "locked"
	action.custom_minimum_size = Vector2(200, 88)
	var qid := quest_id
	action.pressed.connect(func() -> void: _on_quest_pressed(qid))
	row.add_child(action)
	return panel


func _action_label(status: String) -> String:
	match status:
		"available":
			return "Начать"
		"active":
			return "Продолжить"
		"completed":
			return "Повтор"
		_:
			return "—"


func _on_quest_pressed(quest_id: String) -> void:
	var status := GameState.quest_status(quest_id)
	if status == "locked":
		return
	if status == "completed":
		# Replay: clear quest battles only for this quest? Keep simple — jump to location in read-only
		GameState.active_quest_id = quest_id
		var q: Dictionary = GameState.catalog.get_quest(quest_id)
		var battles: Array = q.get("battle_ids", [])
		GameState.active_battle_id = str(battles[0]) if not battles.is_empty() else ""
		GameState.pending_dialogue_quest_id = ""
		GameState.save_game()
		SceneNav.to_location(get_tree())
		return
	if not GameState.start_quest(quest_id):
		return
	SceneNav.to_location(get_tree())


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
