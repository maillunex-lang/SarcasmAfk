extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_HOME)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Ещё", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("MVP хаб · дополнительные экраны", 22, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 20, DesignTokens.COLOR_ACCENT_CYAN))

	var links := [
		["Отряд (5)", AssetPaths.ICON_BATTLE, func() -> void: SceneNav.to_party(get_tree())],
		["Инвентарь", AssetPaths.ICON_INVENTORY, func() -> void: SceneNav.to_inventory(get_tree())],
		["Призыв", AssetPaths.ICON_SUMMON, func() -> void: SceneNav.to_gacha(get_tree())],
		["События", AssetPaths.ICON_EVENTS, func() -> void: SceneNav.to_events(get_tree())],
		["Гильдия", AssetPaths.ICON_GUILD, func() -> void: SceneNav.to_guild(get_tree())],
		["Арена", AssetPaths.ICON_ARENA, func() -> void: SceneNav.to_arena(get_tree())],
		["Экспедиции", AssetPaths.ICON_EXPEDITION, func() -> void: SceneNav.to_expedition(get_tree())],
		["Кампания", AssetPaths.ICON_QUEST, func() -> void: SceneNav.to_campaign(get_tree())],
	]
	for item in links:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)
		var icon := TextureRect.new()
		icon.texture = AssetPaths.tex(str(item[1]))
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var btn := DesignTokens.make_button(str(item[0]), false)
		btn.pressed.connect(item[2])
		row.add_child(btn)

	var pad := Control.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(pad)
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(bottom)
	HubChrome.attach(self, get_tree(), "more")
