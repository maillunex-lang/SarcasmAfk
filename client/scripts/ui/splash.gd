extends "res://scripts/ui/screen_base.gd"

var _timer: Timer
var _logo: TextureRect
var _brand: Label


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.BG_SPLASH)

	var veil := ColorRect.new()
	veil.color = Color(DesignTokens.COLOR_BG_NAVY, 0.28)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", DesignTokens.SPACE_MD)

	_logo = TextureRect.new()
	_logo.texture = AssetPaths.tex(AssetPaths.LOGO)
	_logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(0, 460)
	_logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_logo.modulate = Color(1, 1, 1, 0)
	vbox.add_child(_logo)

	_brand = DesignTokens.make_display_label(DesignTokens.DISPLAY_NAME, 52)
	_brand.modulate = Color(1, 1, 1, 0)
	vbox.add_child(_brand)

	var sub := DesignTokens.make_label(DesignTokens.SLOGAN, 24, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(sub)

	var skip := DesignTokens.make_button("Продолжить", true)
	skip.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(skip)

	_timer = Timer.new()
	_timer.wait_time = 2.4
	_timer.one_shot = true
	_timer.timeout.connect(func() -> void: SceneNav.to_home(get_tree()))
	add_child(_timer)
	_timer.start()
	_fade_in()


func _fade_in() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_logo, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_brand, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
