extends "res://scripts/ui/screen_base.gd"
## Location hub for the active CH01 quest (L01 art reused as placeholder).


func _ready() -> void:
	super._ready()
	var loc: Dictionary = GameState.current_location()
	if loc.is_empty() and GameState.active_quest_id == "":
		# Fallback: show L01 if opened without active quest
		loc = GameState.catalog.get_location("L01")

	var loc_id := str(loc.get("location_id", "L01"))
	_add_location_layers(loc_id)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	var loc_name := str(loc.get("name", loc_id))
	vbox.add_child(DesignTokens.make_label("%s · %s" % [loc_id, loc_name], 36, DesignTokens.COLOR_ACCENT_GOLD))

	var quest: Dictionary = GameState.current_quest()
	var quest_line := "Нет активного квеста"
	if not quest.is_empty():
		quest_line = "%s · %s" % [str(quest.get("quest_id", "")), str(quest.get("title", ""))]
	vbox.add_child(DesignTokens.make_label(quest_line, 24, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label(str(loc.get("description", "")), 20, DesignTokens.COLOR_TEXT_MUTED))

	var prop := TextureRect.new()
	prop.texture = AssetPaths.tex(AssetPaths.L01_TERMINAL)
	prop.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prop.custom_minimum_size = Vector2(0, 360)
	prop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(prop)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	if GameState.needs_dialogue():
		var dialog_btn := DesignTokens.make_button("Диалог квеста", true)
		dialog_btn.pressed.connect(func() -> void: SceneNav.to_dialog(get_tree()))
		vbox.add_child(dialog_btn)

	var battle_id := GameState.active_battle_id
	if battle_id != "":
		var battle_btn := DesignTokens.make_button("В бой %s" % battle_id, not GameState.needs_dialogue())
		battle_btn.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
		vbox.add_child(battle_btn)
	elif GameState.active_quest_id != "" and GameState.is_quest_completed(GameState.active_quest_id):
		vbox.add_child(DesignTokens.make_label("Квест уже завершён — можно повторить бой из кампании.", 20, DesignTokens.COLOR_SUCCESS_MINT))
	elif GameState.active_quest_id != "":
		# Completed all battles but status lag — offer campaign
		pass

	var camp := DesignTokens.make_button("К списку квестов", false)
	camp.pressed.connect(func() -> void: SceneNav.to_campaign(get_tree()))
	vbox.add_child(camp)

	var back := DesignTokens.make_button("На главную", false)
	back.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(back)


func _add_location_layers(loc_id: String) -> void:
	# Full parallax only for L01 drafts; others use mid/hint as single plane.
	if loc_id == "L01":
		_add_layer(AssetPaths.L01_SKY, 0)
		_add_layer(AssetPaths.L01_FAR, 1)
		_add_layer(AssetPaths.L01_MID, 2)
		return
	var hint := str(GameState.catalog.get_location(loc_id).get("bg_hint", AssetPaths.L01_MID))
	_add_layer(hint if hint != "" else AssetPaths.L01_MID, 0)


func _add_layer(path: String, z: int) -> void:
	var layer := TextureRect.new()
	layer.texture = AssetPaths.tex(path)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = z
	add_child(layer)
