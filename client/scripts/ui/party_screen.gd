extends "res://scripts/ui/screen_base.gd"

var _slot_labels: Array = []
var _slot_portraits: Array = []


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_HEROES)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Отряд · 5 героев · 2 линии", 36, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Фронт бьют первыми. Тыл — маги/поддержка.", 22, DesignTokens.COLOR_TEXT_MUTED))

	for i in range(5):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)
		var slot_i := i
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(96, 96)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(portrait)
		_slot_portraits.append(portrait)
		var lab := DesignTokens.make_label(_slot_text(i), 24, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
		_slot_labels.append(lab)
		_apply_portrait(i)
		var btn := DesignTokens.make_button("Сменить", false)
		btn.custom_minimum_size = Vector2(220, 80)
		btn.pressed.connect(func() -> void: _cycle_slot(slot_i))
		row.add_child(btn)

	var front := DesignTokens.make_label(_rows_summary(), 22, DesignTokens.COLOR_ACCENT_CYAN)
	front.name = "RowsSummary"
	vbox.add_child(front)

	var battle := DesignTokens.make_button("В бой (активный)", true)
	battle.pressed.connect(func() -> void:
		if GameState.active_battle_id == "":
			GameState.active_battle_id = "B01"
		GameState.save_game()
		SceneNav.to_battle(get_tree())
	)
	vbox.add_child(battle)

	var loc := DesignTokens.make_button("К локации", false)
	loc.pressed.connect(func() -> void: SceneNav.to_location(get_tree()))
	vbox.add_child(loc)

	var back := DesignTokens.make_button("К коллекции", false)
	back.pressed.connect(func() -> void: SceneNav.to_heroes(get_tree()))
	vbox.add_child(back)


func _slot_text(i: int) -> String:
	var id := str(GameState.party_ids[i]) if i < GameState.party_ids.size() else ""
	var h := GameState.get_hero(id)
	if h.is_empty():
		return "Слот %d · пусто" % (i + 1)
	return "Слот %d · %s (%s / %s)" % [i + 1, str(h.get("name", id)), str(h.get("row", "")), str(h.get("class", ""))]


func _apply_portrait(i: int) -> void:
	if i < 0 or i >= _slot_portraits.size():
		return
	var portrait: TextureRect = _slot_portraits[i]
	var id := str(GameState.party_ids[i]) if i < GameState.party_ids.size() else ""
	if id == "":
		portrait.texture = null
		return
	portrait.texture = AssetPaths.tex(AssetPaths.hero_portrait(id))


func _rows_summary() -> String:
	var f := 0
	var b := 0
	for id in GameState.party_ids:
		var h := GameState.get_hero(str(id))
		if h.is_empty():
			continue
		if str(h.get("row", "")) == "front":
			f += 1
		else:
			b += 1
	return "Линии: фронт %d · тыл %d" % [f, b]


func _cycle_slot(index: int) -> void:
	var owned: Array = []
	for h in GameState.heroes_catalog:
		var id := str(h.get("id", ""))
		if bool(GameState.owned_heroes.get(id, false)):
			owned.append(id)
	if owned.is_empty():
		return
	var cur := str(GameState.party_ids[index]) if index < GameState.party_ids.size() else ""
	var at: int = owned.find(cur)
	var nxt: String = str(owned[(at + 1) % owned.size()])
	GameState.set_party_slot(index, nxt)
	(_slot_labels[index] as Label).text = _slot_text(index)
	_apply_portrait(index)
	for c in get_children():
		_refresh_summary_walk(c)


func _refresh_summary_walk(n: Node) -> void:
	if n is Label and (n as Label).text.begins_with("Линии:"):
		(n as Label).text = _rows_summary()
	for c in n.get_children():
		_refresh_summary_walk(c)
