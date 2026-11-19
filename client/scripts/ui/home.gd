extends "res://scripts/ui/screen_base.gd"
## CITY-HUB-001 Stage G — interactive Ufa city hub (approved Stage 0 canvas).


const BUILDINGS_PATH := "res://data/city/ufa_buildings.json"

var _world: Control
var _tip: Label
var _dragging := false
var _drag_last := Vector2.ZERO
var _world_size := Vector2(2400, 1400)
var _cam := Vector2(660, 120)
var _buildings: Array = []
var _dragon: Control
var _marshrutka: Control
var _papers: Array = []
var _anim_t := 0.0
var _hotspots: Dictionary = {}


func _ready() -> void:
	super._ready()
	_load_city_data()
	_build_city()
	_build_chrome()
	_spawn_decor()
	set_process(true)


func _load_city_data() -> void:
	if not FileAccess.file_exists(BUILDINGS_PATH):
		push_error("Missing city data: %s" % BUILDINGS_PATH)
		return
	var raw := FileAccess.get_file_as_string(BUILDINGS_PATH)
	var data: Variant = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid city JSON")
		return
	var world: Dictionary = data.get("world", {})
	_world_size = Vector2(float(world.get("width", 2400)), float(world.get("height", 1400)))
	var start: Dictionary = data.get("camera_start", {})
	_cam = Vector2(float(start.get("x", 660)), float(start.get("y", 120)))
	_buildings = data.get("buildings", [])


func _build_city() -> void:
	var clip := Control.new()
	clip.name = "CityClip"
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(clip)
	clip.gui_input.connect(_on_city_input)

	_world = Control.new()
	_world.name = "CityWorld"
	_world.custom_minimum_size = _world_size
	_world.size = _world_size
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_world)

	_add_layer(AssetPaths.CITY_UFA_SKY, 0)
	_add_layer(AssetPaths.CITY_UFA_FAR, 1)
	_add_layer(AssetPaths.CITY_UFA_MID, 2)
	_add_layer(AssetPaths.CITY_UFA_ROAD, 3)

	for b in _buildings:
		if typeof(b) != TYPE_DICTIONARY:
			continue
		_add_building(b as Dictionary)

	_apply_camera()


func _add_layer(path: String, z: int) -> void:
	var layer := TextureRect.new()
	layer.texture = AssetPaths.tex(path)
	layer.position = Vector2.ZERO
	layer.size = _world_size
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = z
	_world.add_child(layer)


func _add_building(b: Dictionary) -> void:
	var id := str(b.get("id", ""))
	var btn := Button.new()
	btn.name = "Building_%s" % id
	btn.position = Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
	btn.custom_minimum_size = Vector2(float(b.get("w", 200)), float(b.get("h", 180)))
	btn.size = btn.custom_minimum_size
	btn.z_index = 10
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var locked := bool(b.get("locked", false))
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var base_col := DesignTokens.COLOR_BG_DEEP
	if id == "summon":
		base_col = DesignTokens.COLOR_BG_ELEVATED
	elif id == "campaign":
		base_col = Color(DesignTokens.COLOR_ACCENT_GOLD, 0.35)
	elif id == "afk":
		base_col = Color(DesignTokens.COLOR_ACCENT_CYAN, 0.28)
	elif id == "arena":
		base_col = Color(DesignTokens.COLOR_TEXT_MUTED, 0.35)

	normal.bg_color = Color(base_col, 0.82 if not locked else 0.45)
	normal.border_color = DesignTokens.COLOR_ACCENT_GOLD if not locked else DesignTokens.COLOR_TEXT_MUTED
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(18)
	hover.bg_color = Color(base_col, 0.95)
	hover.border_color = DesignTokens.COLOR_ACCENT_CYAN
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(18)
	pressed.bg_color = Color(base_col, 1.0)
	pressed.border_color = DesignTokens.COLOR_ACCENT_GOLD
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(18)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", normal)
	btn.text = ""

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)

	var icon := TextureRect.new()
	icon.texture = AssetPaths.tex(_icon_for(id))
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	var title := DesignTokens.make_label(str(b.get("name", id)), 22, DesignTokens.COLOR_TEXT_IVORY)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	if locked:
		var lock_lbl := DesignTokens.make_label("ЗАКРЫТО", 18, DesignTokens.COLOR_DANGER_CORAL)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lock_lbl)

	var notify := str(b.get("notify", ""))
	if notify != "":
		var badge := _make_notify_badge(notify)
		badge.position = Vector2(btn.size.x - 56, 8)
		btn.add_child(badge)

	btn.pressed.connect(func() -> void: _on_building_pressed(b))
	btn.mouse_entered.connect(func() -> void: _set_tip(str(b.get("tip", b.get("name", "")))))
	btn.mouse_exited.connect(func() -> void: _set_tip("Тяни карту · нажми здание"))
	_world.add_child(btn)
	_hotspots[id] = btn


func _icon_for(id: String) -> String:
	match id:
		"summon":
			return AssetPaths.ICON_SUMMON
		"guild":
			return AssetPaths.ICON_GUILD
		"tavern":
			return AssetPaths.ICON_HEROES
		"forge":
			return AssetPaths.ICON_INVENTORY
		"shop":
			return AssetPaths.ICON_SHOP
		"campaign":
			return AssetPaths.ICON_QUEST
		"arena":
			return AssetPaths.ICON_ARENA
		"dock":
			return AssetPaths.ICON_EXPEDITION
		"hall":
			return AssetPaths.ICON_SETTINGS
		"afk":
			return AssetPaths.ICON_AFK
		_:
			return AssetPaths.ICON_HOME


func _make_notify_badge(kind: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := DesignTokens.make_panel_style(DesignTokens.COLOR_ACCENT_GOLD, 12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	badge.add_theme_stylebox_override("panel", style)
	var text := "!"
	if kind == "afk":
		var hours := GameState.afk_capped_hours()
		text = "%dч" % int(hours) if hours >= 1.0 else "AFK"
	elif kind == "campaign":
		text = "★"
	elif kind == "summon":
		text = "!"
	badge.add_child(DesignTokens.make_label(text, 18, DesignTokens.COLOR_TEXT_ON_GOLD))
	return badge


func _build_chrome() -> void:
	var top := PanelContainer.new()
	top.name = "CityTopBar"
	top.z_index = 40
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 16
	top.offset_bottom = 100
	top.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.9), 16)
	)
	add_child(top)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	top.add_child(row)

	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 2)
	row.add_child(brand)
	brand.add_child(DesignTokens.make_label("Уфа", 26, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	brand.add_child(DesignTokens.make_label("столица Абсурда", 16, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	for pair in [
		[AssetPaths.ICON_SOFT, str(GameState.soft_currency)],
		[AssetPaths.ICON_HARD, str(GameState.hard_currency)],
		[AssetPaths.ICON_TICKET, str(GameState.summon_tickets)],
	]:
		row.add_child(_currency_chip(str(pair[0]), str(pair[1])))

	# Mid-quest continue strip (single CTA, not a tile grid).
	var mid := GameState.mid_quest_continue()
	if not mid.is_empty():
		var cont := DesignTokens.make_button(str(mid.get("label", "Продолжить")), true)
		cont.z_index = 41
		cont.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		cont.anchor_left = 0.12
		cont.anchor_right = 0.88
		cont.offset_top = -280
		cont.offset_bottom = -200
		cont.offset_left = 0
		cont.offset_right = 0
		var dest := str(mid.get("dest", "location"))
		cont.pressed.connect(func() -> void: _continue_mid_quest(dest))
		add_child(cont)

	var tip_panel := PanelContainer.new()
	tip_panel.name = "CityTip"
	tip_panel.z_index = 40
	tip_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tip_panel.offset_left = 16
	tip_panel.offset_right = -16
	tip_panel.offset_top = -250
	tip_panel.offset_bottom = -180
	tip_panel.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.88), 14)
	)
	add_child(tip_panel)
	_tip = DesignTokens.make_label("Тяни карту · нажми здание", 20, DesignTokens.COLOR_TEXT_MUTED)
	tip_panel.add_child(_tip)

	HubChrome.attach(self, get_tree(), "home")


func _currency_chip(icon_path: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.95), 12)
	)
	var style: StyleBoxFlat = chip.get_theme_stylebox("panel")
	style.content_margin_left = 8
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)
	var ic := TextureRect.new()
	ic.texture = AssetPaths.tex(icon_path)
	ic.custom_minimum_size = Vector2(32, 32)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ic)
	row.add_child(DesignTokens.make_label(value, 20, DesignTokens.COLOR_ACCENT_CYAN))
	return chip


func _set_tip(text: String) -> void:
	if _tip != null:
		_tip.text = text


func _spawn_decor() -> void:
	# Bureaucratic dragon
	_dragon = _make_decor_blob(DesignTokens.COLOR_ACCENT_GOLD, Vector2(96, 40), "Дракон")
	_dragon.z_index = 20
	_world.add_child(_dragon)

	# Magical marshrutka
	_marshrutka = _make_decor_blob(DesignTokens.COLOR_ACCENT_CYAN, Vector2(120, 44), "22А")
	_marshrutka.z_index = 21
	_world.add_child(_marshrutka)

	for i in range(5):
		var paper := _make_decor_blob(DesignTokens.COLOR_TEXT_IVORY, Vector2(28, 20), "")
		paper.z_index = 19
		_world.add_child(paper)
		_papers.append(paper)

	# Living stamp near town hall
	var stamp := _make_decor_blob(DesignTokens.COLOR_DANGER_CORAL, Vector2(56, 56), "ПЕЧАТЬ")
	stamp.position = Vector2(640, 280)
	stamp.z_index = 18
	_world.add_child(stamp)
	var tw := create_tween().set_loops()
	tw.tween_property(stamp, "rotation", 0.2, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(stamp, "rotation", -0.2, 0.8).set_trans(Tween.TRANS_SINE)

	# Summon queue silhouettes
	for i in range(5):
		var q := ColorRect.new()
		q.color = DesignTokens.COLOR_ACCENT_GOLD if i % 2 == 0 else DesignTokens.COLOR_BG_ELEVATED
		q.size = Vector2(18, 36)
		q.position = Vector2(1220 + i * 28, 520)
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.z_index = 15
		_world.add_child(q)


func _make_decor_blob(color: Color, size: Vector2, label: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = size
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := DesignTokens.make_panel_style(color, 10)
	p.add_theme_stylebox_override("panel", style)
	if label != "":
		var on_col := DesignTokens.COLOR_TEXT_ON_GOLD if color == DesignTokens.COLOR_ACCENT_GOLD else DesignTokens.COLOR_BG_NAVY
		if color == DesignTokens.COLOR_ACCENT_CYAN:
			on_col = DesignTokens.COLOR_BG_NAVY
		if color == DesignTokens.COLOR_DANGER_CORAL:
			on_col = DesignTokens.COLOR_TEXT_IVORY
		p.add_child(DesignTokens.make_label(label, 16, on_col))
	return p


func _process(delta: float) -> void:
	_anim_t += delta
	if _dragon != null:
		var dx := fmod(_anim_t * 90.0, _world_size.x + 140.0) - 70.0
		var dy := 160.0 + sin(_anim_t * 1.4) * 18.0
		_dragon.position = Vector2(dx, dy)
		for i in range(_papers.size()):
			var paper: Control = _papers[i]
			paper.position = Vector2(dx - 40.0 - i * 22.0, dy + 36.0 + i * 14.0 + sin(_anim_t * 3.0 + i) * 4.0)
			paper.rotation = 0.2 * i
	if _marshrutka != null:
		# Drive along the road; pause briefly each cycle (magical marshrutka).
		var cycle := fmod(_anim_t, 8.0)
		var progress := cycle / 8.0
		if cycle >= 3.2 and cycle <= 4.0:
			progress = 3.2 / 8.0
		var mx := progress * (_world_size.x + 160.0) - 80.0
		_marshrutka.position = Vector2(mx, 1000.0)


func _on_city_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			_drag_last = mb.position
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var delta: Vector2 = mm.position - _drag_last
		_drag_last = mm.position
		_cam -= delta
		_apply_camera()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_dragging = st.pressed
		_drag_last = st.position
	elif event is InputEventScreenDrag and _dragging:
		var sd := event as InputEventScreenDrag
		_cam -= sd.relative
		_apply_camera()


func _apply_camera() -> void:
	var view := get_viewport_rect().size
	if view.x <= 1.0 or view.y <= 1.0:
		view = Vector2(1080, 1920)
	var max_x := maxf(0.0, _world_size.x - view.x)
	var max_y := maxf(0.0, _world_size.y - view.y)
	_cam.x = clampf(_cam.x, 0.0, max_x)
	_cam.y = clampf(_cam.y, 0.0, max_y)
	if _world != null:
		_world.position = -_cam


func _on_building_pressed(b: Dictionary) -> void:
	var dest := str(b.get("dest", ""))
	var locked := bool(b.get("locked", false))
	_set_tip(str(b.get("name", dest)))
	if locked:
		# Arena stays a locked stub destination (D-SCOPE-01).
		SceneNav.to_arena(get_tree())
		return
	match dest:
		"gacha":
			SceneNav.to_gacha(get_tree())
		"guild":
			SceneNav.to_guild(get_tree())
		"heroes":
			SceneNav.to_heroes(get_tree())
		"inventory":
			SceneNav.to_inventory(get_tree())
		"shop":
			SceneNav.to_shop(get_tree())
		"campaign":
			SceneNav.to_campaign(get_tree())
		"arena":
			SceneNav.to_arena(get_tree())
		"expedition":
			SceneNav.to_expedition(get_tree())
		"more":
			SceneNav.to_more(get_tree())
		"afk":
			SceneNav.to_afk(get_tree())
		_:
			SceneNav.to_more(get_tree())


func _continue_mid_quest(dest: String) -> void:
	match dest:
		"dialog":
			SceneNav.to_dialog(get_tree())
		"party":
			SceneNav.to_party(get_tree())
		"battle":
			SceneNav.to_battle(get_tree())
		"location":
			SceneNav.to_location(get_tree())
		_:
			SceneNav.to_map(get_tree())
