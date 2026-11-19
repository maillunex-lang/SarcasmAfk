class_name CombatFxOverlay
extends Control
## Plays TEMP shared VFX atlas bursts + one-shot SFX over a battle unit card.

const FRAME_DEFAULT := 128
const FPS := 14.0

var _sheet: Texture2D
var _frames: int = 6
var _fw: int = FRAME_DEFAULT
var _fh: int = FRAME_DEFAULT
var _frame: int = 0
var _accum: float = 0.0
var _playing: bool = false
var _atlas: AtlasTexture
var _rect: TextureRect
var _player: AudioStreamPlayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect = TextureRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	_atlas = AtlasTexture.new()
	_rect.texture = _atlas
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	visible = false


func play_vfx(vfx_path: String) -> void:
	if vfx_path == "" or not ResourceLoader.exists(vfx_path):
		return
	var meta_path := vfx_path.get_basename() + ".json"
	_sheet = AssetPaths.tex(vfx_path)
	if _sheet == null:
		return
	_frames = 6
	_fw = FRAME_DEFAULT
	_fh = FRAME_DEFAULT
	if ResourceLoader.exists(meta_path):
		var file := FileAccess.open(meta_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				var meta: Dictionary = parsed
				_frames = int(meta.get("frame_count", 6))
				_fw = int(meta.get("frame_w", FRAME_DEFAULT))
				_fh = int(meta.get("frame_h", FRAME_DEFAULT))
	_frame = 0
	_accum = 0.0
	_playing = true
	visible = true
	_apply()


func play_sfx(sfx_path: String) -> void:
	if sfx_path == "" or not ResourceLoader.exists(sfx_path):
		return
	var stream: AudioStream = load(sfx_path) as AudioStream
	if stream == null:
		return
	_player.stream = stream
	_player.play()


func play_pair(vfx_path: String, sfx_path: String) -> void:
	play_sfx(sfx_path)
	play_vfx(vfx_path)


func _process(delta: float) -> void:
	if not _playing:
		return
	_accum += delta
	var step := 1.0 / FPS
	while _accum >= step:
		_accum -= step
		_frame += 1
		if _frame >= _frames:
			_playing = false
			visible = false
			return
		_apply()


func _apply() -> void:
	if _sheet == null:
		return
	_atlas.atlas = _sheet
	_atlas.region = Rect2(_frame * _fw, 0, _fw, _fh)
	_rect.texture = _atlas
