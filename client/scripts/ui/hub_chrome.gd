class_name HubChrome
extends RefCounted
## Bottom navigation for Phase 1 hub screens (mock MVP).

const ITEMS := [
	{"id": "home", "label": "Дом", "scene": "home"},
	{"id": "map", "label": "Карта", "scene": "map"},
	{"id": "heroes", "label": "Герои", "scene": "heroes"},
	{"id": "afk", "label": "AFK", "scene": "afk"},
	{"id": "more", "label": "Ещё", "scene": "more"},
]


static func attach(parent: Control, tree: SceneTree, active_id: String) -> void:
	var bar := HBoxContainer.new()
	bar.name = "HubNav"
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -140
	bar.offset_bottom = -24
	bar.offset_left = 24
	bar.offset_right = -24
	bar.add_theme_constant_override("separation", 8)
	bar.z_index = 50
	parent.add_child(bar)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.92), 16))
	bar.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	for item in ITEMS:
		var id := str(item.get("id", ""))
		var btn := Button.new()
		btn.text = str(item.get("label", id))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 96)
		btn.disabled = id == active_id
		btn.add_theme_font_size_override("font_size", 26)
		var scene_key := str(item.get("scene", ""))
		btn.pressed.connect(func() -> void: _go(tree, scene_key))
		row.add_child(btn)


static func _go(tree: SceneTree, scene_key: String) -> void:
	match scene_key:
		"home":
			SceneNav.to_home(tree)
		"map":
			SceneNav.to_map(tree)
		"heroes":
			SceneNav.to_heroes(tree)
		"afk":
			SceneNav.to_afk(tree)
		"more":
			SceneNav.to_more(tree)
		_:
			SceneNav.to_home(tree)
