extends SceneTree
## VO Stage F gallery gate: Theme + H13–H36 dialog busts + on-disk gallery pack.
## Viewport screenshots are unavailable under headless dummy renderer — gallery PNGs
## are produced by scripts/generate_visual_gallery.py and verified here.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame

	if not ResourceLoader.exists("res://themes/bashlegends_theme.tres"):
		push_error("FAIL missing bashlegends_theme.tres")
		quit(1)
		return
	var theme: Theme = load("res://themes/bashlegends_theme.tres")
	if theme == null or theme.default_font_size < 16:
		push_error("FAIL theme invalid")
		quit(1)
		return
	print("OK theme default_font_size=", theme.default_font_size)

	for i in range(13, 37):
		var hid := "H%d" % i
		var path := "res://assets/dialogs/dialog_portrait_%s.jpg" % hid
		if not ResourceLoader.exists(path):
			push_error("FAIL missing %s" % path)
			failed = true
			continue
		if AssetPaths.dialog_portrait_for(hid) == null:
			push_error("FAIL dialog_portrait_for %s" % hid)
			failed = true
	if not failed:
		print("OK dialog busts H13–H36")

	var gallery_root := ProjectSettings.globalize_path("res://").path_join("../docs/reports/visual_gallery")
	var required := [
		"after_home.png",
		"after_dialog.png",
		"after_gacha.png",
		"compare_home.png",
		"after_dialog_busts_sample.png",
		"MANIFEST.md",
	]
	for name in required:
		var p := gallery_root.path_join(name)
		if not FileAccess.file_exists(p):
			push_error("FAIL missing gallery file %s" % p)
			failed = true
		else:
			print("OK gallery ", name)

	if failed:
		push_error("smoke_visual_gallery FAILED")
		quit(1)
		return
	print("smoke_visual_gallery PASSED")
	quit(0)
