extends "res://scripts/ui/screen_base.gd"

var _log: VBoxContainer
var _input: LineEdit
var _channel: String = "global"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_CHAT)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vbox.add_child(head)
	var chat_icon := TextureRect.new()
	chat_icon.texture = AssetPaths.tex(AssetPaths.ICON_CHAT)
	chat_icon.custom_minimum_size = Vector2(64, 64)
	chat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(chat_icon)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	titles.add_child(DesignTokens.make_label("Чат", 36, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(DesignTokens.make_label("Канал: global · отправитель только с сервера", 16, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_log = VBoxContainer.new()
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "Сообщение…"
	_input.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(_input)
	var send := DesignTokens.make_button("Отправить", true)
	send.pressed.connect(_on_send)
	vbox.add_child(send)
	var refresh := DesignTokens.make_button("Обновить", false)
	refresh.pressed.connect(_reload)
	vbox.add_child(refresh)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)
	_reload()


func _reload() -> void:
	for c in _log.get_children():
		c.queue_free()
	var res: Dictionary = GameState.api.chat_history(_channel, 40)
	var msgs: Array = res.get("messages", [])
	if msgs.is_empty():
		_log.add_child(DesignTokens.make_label("Пока тихо. Напишите первым.", 20, DesignTokens.COLOR_TEXT_MUTED))
		return
	for m in msgs:
		var name := str(m.get("display_name", "?"))
		var body := str(m.get("body", ""))
		var t := str(m.get("created_at", ""))
		_log.add_child(DesignTokens.make_label("[%s] %s: %s" % [t.substr(11, 8), name, body], 18, DesignTokens.COLOR_TEXT_IVORY))


func _on_send() -> void:
	var text := _input.text.strip_edges()
	if text.is_empty():
		return
	var res: Dictionary = GameState.api.chat_send(_channel, text, "Командир")
	_input.text = ""
	if not bool(res.get("ok", false)):
		_log.add_child(DesignTokens.make_label("Ошибка отправки / лимит", 18, DesignTokens.COLOR_DANGER_CORAL))
		return
	_reload()
