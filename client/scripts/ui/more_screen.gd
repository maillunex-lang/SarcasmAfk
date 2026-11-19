extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)
	vbox.add_child(DesignTokens.make_label("Ещё", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("MVP хаб · дополнительные экраны", 22, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 20, DesignTokens.COLOR_ACCENT_CYAN))

	var links := [
		["Отряд (5)", func() -> void: SceneNav.to_party(get_tree())],
		["Инвентарь", func() -> void: SceneNav.to_inventory(get_tree())],
		["Призыв", func() -> void: SceneNav.to_gacha(get_tree())],
		["События", func() -> void: SceneNav.to_events(get_tree())],
		["Гильдия", func() -> void: SceneNav.to_guild(get_tree())],
		["Арена", func() -> void: SceneNav.to_arena(get_tree())],
		["Экспедиции", func() -> void: SceneNav.to_expedition(get_tree())],
		["Кампания", func() -> void: SceneNav.to_campaign(get_tree())],
	]
	for item in links:
		var btn := DesignTokens.make_button(str(item[0]), false)
		btn.pressed.connect(item[1])
		vbox.add_child(btn)

	var pad := Control.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(pad)
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(bottom)
	HubChrome.attach(self, get_tree(), "more")
