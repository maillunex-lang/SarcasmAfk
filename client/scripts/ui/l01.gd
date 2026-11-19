extends "res://scripts/ui/screen_base.gd"
## Location hub with parallax layers for CH01 L01–L10.


func _ready() -> void:
	super._ready()
	var loc: Dictionary = GameState.current_location()
	if loc.is_empty() and GameState.active_quest_id == "":
		loc = GameState.catalog.get_location("L01")

	var loc_id := str(loc.get("location_id", "L01"))
	_add_location_layers(loc_id, loc)

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
	vbox.add_child(DesignTokens.make_label(_step_hint(), 22, DesignTokens.COLOR_ACCENT_CYAN))
	vbox.add_child(DesignTokens.make_label(str(loc.get("description", "")), 20, DesignTokens.COLOR_TEXT_MUTED))

	# Prop: L01 terminal; other locs show mid crop hint via icon quest
	var prop := TextureRect.new()
	if loc_id == "L01":
		prop.texture = AssetPaths.tex(AssetPaths.L01_TERMINAL)
	else:
		prop.texture = AssetPaths.tex(AssetPaths.location_layer(loc_id, "mid"))
	prop.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prop.custom_minimum_size = Vector2(0, 360)
	prop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(prop)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	if GameState.needs_dialogue():
		var dialog_btn := DesignTokens.make_button("1 · Диалог квеста", true)
		dialog_btn.pressed.connect(func() -> void: SceneNav.to_dialog(get_tree()))
		vbox.add_child(dialog_btn)

	var battle_id := GameState.active_battle_id
	var can_fight := battle_id != "" and not GameState.needs_dialogue()
	if can_fight:
		var party_btn := DesignTokens.make_button("2 · Собрать отряд", true)
		party_btn.pressed.connect(func() -> void: SceneNav.to_party(get_tree()))
		vbox.add_child(party_btn)
		var battle_btn := DesignTokens.make_button("3 · В бой %s" % battle_id, false)
		battle_btn.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
		vbox.add_child(battle_btn)
	elif GameState.active_quest_id != "" and GameState.is_quest_completed(GameState.active_quest_id):
		vbox.add_child(DesignTokens.make_label("Квест уже завершён — можно повторить бой из кампании.", 20, DesignTokens.COLOR_SUCCESS_MINT))

	var poi := DesignTokens.make_button("Точки интереса / побочные", true)
	poi.pressed.connect(func() -> void: SceneNav.to_poi(get_tree()))
	vbox.add_child(poi)

	var camp := DesignTokens.make_button("К списку квестов", false)
	camp.pressed.connect(func() -> void: SceneNav.to_campaign(get_tree()))
	vbox.add_child(camp)

	var back := DesignTokens.make_button("На главную", false)
	back.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(back)


func _step_hint() -> String:
	if GameState.needs_dialogue():
		return "Цепочка: диалог → отряд → автобой"
	if GameState.active_battle_id != "":
		return "Отряд → бой %s (ультимейт вручную)" % GameState.active_battle_id
	if GameState.active_quest_id != "" and GameState.is_quest_completed(GameState.active_quest_id):
		return "Квест закрыт · следующий этап в кампании"
	return "Выберите квест в кампании CH01"


func _add_location_layers(loc_id: String, loc: Dictionary) -> void:
	var layers: Dictionary = loc.get("layers", {})
	if typeof(layers) == TYPE_DICTIONARY and not layers.is_empty():
		_add_layer(str(layers.get("sky", AssetPaths.location_layer(loc_id, "sky"))), 0)
		_add_layer(str(layers.get("far", AssetPaths.location_layer(loc_id, "far"))), 1)
		_add_layer(str(layers.get("mid", AssetPaths.location_layer(loc_id, "mid"))), 2)
		return
	# Fallback L01 classic
	if loc_id == "L01":
		_add_layer(AssetPaths.L01_SKY, 0)
		_add_layer(AssetPaths.L01_FAR, 1)
		_add_layer(AssetPaths.L01_MID, 2)
		return
	var hint := str(loc.get("bg_hint", AssetPaths.L01_MID))
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
