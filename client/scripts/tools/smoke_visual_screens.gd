extends SceneTree
## Headless visual smoke: instantiate key screens and confirm UI trees build.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var paths := [
		"res://scenes/boot/splash.tscn",
		"res://scenes/home/home.tscn",
		"res://scenes/dialog/dialog.tscn",
		"res://scenes/battle/battle.tscn",
		"res://scenes/heroes/heroes.tscn",
		"res://scenes/party/party.tscn",
		"res://scenes/gacha/gacha.tscn",
		"res://scenes/inventory/inventory.tscn",
		"res://scenes/bestiary/bestiary.tscn",
		"res://scenes/guild/guild.tscn",
		"res://scenes/map/map.tscn",
		"res://scenes/shop/shop.tscn",
	]
	var required_tex := [
		AssetPaths.BG_PARTY,
		AssetPaths.BG_BESTIARY,
		AssetPaths.BG_DIALOG,
		AssetPaths.BG_INVENTORY,
		AssetPaths.GACHA_PORTAL,
		AssetPaths.UI_EMPTY_STATE,
		AssetPaths.MAP_UFA,
		AssetPaths.GUILD_ICON_CREST,
		AssetPaths.GUILD_ICON_VAULT,
		AssetPaths.GUILD_ICON_BOARD,
		AssetPaths.gacha_frame("SSR"),
		DesignTokens.FONT_BODY,
		DesignTokens.FONT_DISPLAY,
		"res://themes/bashlegends_theme.tres",
		"res://assets/dialogs/dialog_portrait_H13.jpg",
		"res://assets/dialogs/dialog_portrait_H36.jpg",
	]
	for p in required_tex:
		if not ResourceLoader.exists(p):
			push_error("FAIL missing visual asset %s" % p)
			quit(2)
			return
		print("OK asset ", p)
	for path in paths:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("FAIL load %s" % path)
			quit(3)
			return
		var node: Node = packed.instantiate()
		root.add_child(node)
		await process_frame
		await process_frame
		var n := _count_controls(node)
		if n < 2:
			push_error("FAIL empty UI %s controls=%d" % [path, n])
			quit(4)
			return
		print("OK screen ", path, " controls=", n)
		node.queue_free()
		await process_frame
	print("smoke_visual_screens_ok")
	quit(0)


func _count_controls(n: Node) -> int:
	var c := 1 if n is Control else 0
	for ch in n.get_children():
		c += _count_controls(ch)
	return c
