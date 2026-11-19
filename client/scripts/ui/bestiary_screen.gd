extends "res://scripts/ui/screen_base.gd"
## CH01 Bestiary — unlocks on first encounter (journal_flags / completed battles).


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_BESTIARY if ResourceLoader.exists(AssetPaths.BG_BESTIARY) else AssetPaths.BG_HEROES)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_display_label("Бестиарий Уфы", 44))
	vbox.add_child(DesignTokens.make_label("29 противников CH01 · открывается после встречи", 18, DesignTokens.COLOR_TEXT_MUTED))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var catalog := _load_catalog()
	var unlocked := 0
	for e in catalog:
		var eid := str(e.get("id", ""))
		var seen := _is_unlocked(eid)
		if seen:
			unlocked += 1
		list.add_child(_card(e, seen))

	vbox.add_child(DesignTokens.make_label("Открыто: %d / %d" % [unlocked, catalog.size()], 20, DesignTokens.COLOR_ACCENT_CYAN))
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _load_catalog() -> Array:
	var path := "res://data/enemies/enemy_catalog_ch01.json"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return []
	return data.get("enemies", [])


func _is_unlocked(enemy_id: String) -> bool:
	if bool(GameState.journal_flags.get("bestiary_%s" % enemy_id, false)):
		return true
	# Unlock from any completed battle that lists this enemy_type.
	if GameState.catalog == null:
		return false
	for bid in GameState.completed_battles.keys():
		if not bool(GameState.completed_battles[bid]):
			continue
		var battle: Dictionary = GameState.catalog.get_battle(str(bid))
		for en in battle.get("enemies", []):
			if str(en.get("enemy_type", "")) == enemy_id:
				return true
	return false


func _card(e: Dictionary, unlocked: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(96, 96)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var eid := str(e.get("id", ""))
	if unlocked:
		ic.texture = AssetPaths.tex(AssetPaths.enemy_sprite_for_type(eid))
	else:
		ic.modulate = Color(0.2, 0.2, 0.25, 1)
	row.add_child(ic)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	if unlocked:
		box.add_child(DesignTokens.make_label("%s · %s" % [eid, str(e.get("name", ""))], 22, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		box.add_child(DesignTokens.make_label(str(e.get("archetype", "")), 16, DesignTokens.COLOR_ACCENT_CYAN, HORIZONTAL_ALIGNMENT_LEFT))
		box.add_child(DesignTokens.make_label(str(e.get("lore", "")), 16, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		var sp: Dictionary = e.get("special", {})
		box.add_child(DesignTokens.make_label("Умение: %s" % str(sp.get("name", "—")), 16, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
		var quote := str(e.get("quote", ""))
		if quote != "":
			box.add_child(DesignTokens.make_label("«%s»" % quote, 16, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		var art: Dictionary = e.get("art", {})
		box.add_child(DesignTokens.make_label("Арт: %s" % str(art.get("status", "?")), 14, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	else:
		box.add_child(DesignTokens.make_label("???", 22, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		box.add_child(DesignTokens.make_label("Ещё не встречали в бою.", 16, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	return panel
