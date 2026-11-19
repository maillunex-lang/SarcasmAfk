extends "res://scripts/ui/screen_base.gd"

var _name_in: LineEdit
var _tag_in: LineEdit
var _status: Label


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_GUILD)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Гильдия", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(
		"Live create/join · стоимость создания Draft %d soft" % 500,
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))
	_status = DesignTokens.make_label("…", 20, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(_status)

	_name_in = LineEdit.new()
	_name_in.placeholder_text = "Название"
	_name_in.custom_minimum_size = Vector2(0, 56)
	vbox.add_child(_name_in)
	_tag_in = LineEdit.new()
	_tag_in.placeholder_text = "Тег 3–5"
	_tag_in.custom_minimum_size = Vector2(0, 56)
	vbox.add_child(_tag_in)

	var create_btn := DesignTokens.make_button("Создать гильдию", true)
	create_btn.pressed.connect(_on_create)
	vbox.add_child(create_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "GuildList"
	scroll.add_child(list)

	var chat := DesignTokens.make_button("Чат гильдии / global", false)
	chat.pressed.connect(func() -> void: SceneNav.to_chat(get_tree()))
	vbox.add_child(chat)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)
	_reload(list)


func _reload(list: VBoxContainer = null) -> void:
	if list == null:
		list = find_child("GuildList", true, false) as VBoxContainer
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()
	var res: Dictionary = GameState.api.get_guild()
	var mine = res.get("guild", null)
	if typeof(mine) == TYPE_DICTIONARY and mine != null:
		_status.text = "Вы в: [%s] %s · роль %s" % [
			str(mine.get("tag", "")), str(mine.get("name", "")), str(res.get("role", ""))
		]
	else:
		_status.text = "Нет гильдии · золото %d" % GameState.soft_currency
	var guilds: Array = res.get("list", [])
	if guilds.is_empty():
		list.add_child(DesignTokens.make_label("Список пуст — создайте первую.", 18, DesignTokens.COLOR_TEXT_MUTED))
		return
	for g in guilds:
		if typeof(g) != TYPE_DICTIONARY:
			continue
		var row := HBoxContainer.new()
		row.add_child(DesignTokens.make_label(
			"[%s] %s · %d/%d" % [g.get("tag", ""), g.get("name", ""), g.get("members", 0), g.get("cap", 30)],
			18,
			DesignTokens.COLOR_TEXT_IVORY
		))
		var join := DesignTokens.make_button("Вступить", false)
		var gid := str(g.get("id", ""))
		join.pressed.connect(func() -> void:
			GameState.api.guild_action("join", {"guild_id": gid})
			_reload()
		)
		row.add_child(join)
		list.add_child(row)


func _on_create() -> void:
	var res: Dictionary = GameState.api.guild_action("create", {
		"name": _name_in.text.strip_edges(),
		"tag": _tag_in.text.strip_edges(),
		"description": "",
	})
	if bool(res.get("ok", false)):
		GameState.soft_currency = max(0, GameState.soft_currency - 500)
		GameState.save_game()
		_reload()
	else:
		_status.text = "Не удалось создать (тег/ресурсы/уже в гильдии)"
