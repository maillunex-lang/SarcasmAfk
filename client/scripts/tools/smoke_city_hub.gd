extends SceneTree
## CITY-HUB-001 smoke: Ufa buildings JSON + home city hub hotspots.
## godot4 --headless --path client -s res://scripts/tools/smoke_city_hub.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	await process_frame

	var path := "res://data/city/ufa_buildings.json"
	if not FileAccess.file_exists(path):
		push_error("FAIL missing %s" % path)
		quit(1)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("FAIL city JSON parse")
		quit(1)
		return
	var buildings: Array = data.get("buildings", [])
	if buildings.size() != 10:
		push_error("FAIL expected 10 buildings, got %s" % buildings.size())
		failed = true
	else:
		print("OK buildings=10")

	var required_ids := [
		"summon", "guild", "tavern", "forge", "shop",
		"campaign", "arena", "dock", "hall", "afk",
	]
	var seen := {}
	for b in buildings:
		seen[str(b.get("id", ""))] = true
	for id in required_ids:
		if not seen.has(id):
			push_error("FAIL missing building %s" % id)
			failed = true
	print("OK building ids")

	for layer in [
		AssetPaths.CITY_UFA_SKY,
		AssetPaths.CITY_UFA_FAR,
		AssetPaths.CITY_UFA_MID,
		AssetPaths.CITY_UFA_ROAD,
		AssetPaths.CITY_UFA_PANORAMA,
	]:
		if not ResourceLoader.exists(layer):
			push_error("FAIL missing layer %s" % layer)
			failed = true
	print("OK city layers")

	var packed: PackedScene = load("res://scenes/home/home.tscn")
	if packed == null:
		push_error("FAIL load home.tscn")
		quit(1)
		return
	var home: Node = packed.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	var world := home.get_node_or_null("CityClip/CityWorld")
	if world == null:
		push_error("FAIL CityWorld missing")
		failed = true
	else:
		print("OK CityWorld")

	for id in required_ids:
		var node := home.find_child("Building_%s" % id, true, false)
		if node == null:
			push_error("FAIL hotspot Building_%s" % id)
			failed = true
	print("OK hotspots")

	var arena: Button = home.find_child("Building_arena", true, false) as Button
	if arena == null:
		push_error("FAIL arena button")
		failed = true

	var top := home.get_node_or_null("CityTopBar")
	if top == null:
		push_error("FAIL CityTopBar")
		failed = true
	else:
		print("OK CityTopBar")

	var nav := home.get_node_or_null("HubNav")
	if nav == null:
		push_error("FAIL HubNav")
		failed = true
	else:
		print("OK HubNav")

	for rail_name in ["SideRailLeft", "SideRailRight"]:
		var rail := home.get_node_or_null(rail_name)
		if rail == null:
			push_error("FAIL %s missing" % rail_name)
			failed = true
		else:
			print("OK ", rail_name)

	# Ensure home no longer mounts the old 2×3 quick grid as primary UX.
	if home.find_child("QuickGrid", true, false) != null:
		push_error("FAIL legacy QuickGrid still present")
		failed = true
	else:
		print("OK no QuickGrid")

	home.queue_free()
	await process_frame

	if failed:
		push_error("smoke_city_hub FAILED")
		quit(1)
	else:
		print("smoke_city_hub OK")
		quit(0)
