class_name HubChrome
extends RefCounted
## Bottom navigation for Phase 1 hub screens with icons.

const ITEMS := [
	{"id": "home", "label": "Город", "scene": "home", "icon": AssetPaths.ICON_HOME},
	{"id": "map", "label": "Карта", "scene": "map", "icon": AssetPaths.ICON_MAP},
	{"id": "heroes", "label": "Герои", "scene": "heroes", "icon": AssetPaths.ICON_HEROES},
	{"id": "afk", "label": "AFK", "scene": "afk", "icon": AssetPaths.ICON_AFK},
	{"id": "more", "label": "Ещё", "scene": "more", "icon": AssetPaths.ICON_SETTINGS},
]


static func attach(parent: Control, tree: SceneTree, active_id: String) -> void:
	var bar := HBoxContainer.new()
	bar.name = "HubNav"
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -160
	bar.offset_bottom = -16
	bar.offset_left = 16
	bar.offset_right = -16
	bar.add_theme_constant_override("separation", 8)
	bar.z_index = 50
	parent.add_child(bar)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.94), 16))
	bar.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	for item in ITEMS:
		var id := str(item.get("id", ""))
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(cell)

		var icon := TextureRect.new()
		icon.texture = AssetPaths.tex(str(item.get("icon", "")))
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color(1, 1, 1, 1.0 if id == active_id else 0.75)
		cell.add_child(icon)

		var btn := Button.new()
		btn.text = str(item.get("label", id))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 56)
		btn.disabled = id == active_id
		btn.add_theme_font_size_override("font_size", 22)
		var scene_key := str(item.get("scene", ""))
		btn.pressed.connect(func() -> void: _go(tree, scene_key))
		cell.add_child(btn)


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
