extends "res://scripts/ui/screen_base.gd"

var _lines: Array = []
var _index: int = 0
var _quest_id: String = ""
var _speaker_label: Label
var _body_label: Label
var _portrait: TextureRect
var _progress_label: Label
var _title_label: Label


func _ready() -> void:
	super._ready()
	_quest_id = GameState.pending_dialogue_quest_id
	if _quest_id == "":
		_quest_id = GameState.active_quest_id
	if _quest_id == "":
		_quest_id = "CH01-Q01"
	_load_dialogue()

	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)
	var quest: Dictionary = GameState.catalog.get_quest(_quest_id)
	var title := str(quest.get("title", _quest_id))
	_title_label = DesignTokens.make_label("%s · %s" % [_quest_id, title], 34, DesignTokens.COLOR_ACCENT_GOLD)
	vbox.add_child(_title_label)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	vbox.add_child(row)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(320, 400)
	portrait_panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	row.add_child(portrait_panel)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.custom_minimum_size = Vector2(280, 360)
	portrait_panel.add_child(_portrait)

	var text_panel := PanelContainer.new()
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	row.add_child(text_panel)

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 16)
	text_panel.add_child(text_box)
	_speaker_label = DesignTokens.make_label("", 34, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	text_box.add_child(_speaker_label)
	_body_label = DesignTokens.make_label("", 30, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT)
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.add_child(_body_label)

	_progress_label = DesignTokens.make_label("", 22, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(_progress_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	vbox.add_child(buttons)

	var skip_icon := TextureRect.new()
	skip_icon.texture = AssetPaths.tex(AssetPaths.ICON_SKIP)
	skip_icon.custom_minimum_size = Vector2(88, 88)
	skip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skip_icon.stretch_mode = TextureRect.STRETCH_SCALE
	buttons.add_child(skip_icon)

	var skip := DesignTokens.make_button("Пропуск", false)
	skip.pressed.connect(_finish_dialog)
	buttons.add_child(skip)

	var next_btn := DesignTokens.make_button("Далее", true)
	next_btn.pressed.connect(_on_next)
	buttons.add_child(next_btn)

	_show_line()


func _load_dialogue() -> void:
	var res: Dictionary = GameState.api.get_dialogue(_quest_id, GameState.catalog)
	if bool(res.get("ok", false)):
		var data: Dictionary = res.get("dialogue", {})
		_lines = data.get("lines", [])
		return
	_lines = [{"speaker": "Система", "speaker_id": "SYS", "text": "Диалог не найден: %s" % _quest_id}]


func _show_line() -> void:
	if _lines.is_empty():
		return
	_index = clampi(_index, 0, _lines.size() - 1)
	var line: Dictionary = _lines[_index]
	_speaker_label.text = str(line.get("speaker", "?"))
	_body_label.text = str(line.get("text", ""))
	_portrait.texture = AssetPaths.dialog_portrait_for(str(line.get("speaker_id", "")))
	_progress_label.text = "Реплика %d / %d · статичный портрет" % [_index + 1, _lines.size()]


func _on_next() -> void:
	if _index >= _lines.size() - 1:
		_finish_dialog()
		return
	_index += 1
	_show_line()


func _finish_dialog() -> void:
	GameState.mark_dialogue_seen(_quest_id)
	# Always return to location hub so L01 shows clear next step (battle CTA).
	SceneNav.to_location(get_tree())
