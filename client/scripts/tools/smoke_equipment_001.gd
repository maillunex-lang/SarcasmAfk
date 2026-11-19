extends SceneTree
## Headless EQUIPMENT-001 smoke: catalog, instances, equip, upgrade, salvage.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs: Node = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs == null:
		# Autoload may not exist in bare SceneTree; instantiate catalog locally.
		push_error("GameState missing — run via project main with autoloads")
		quit(1)
		return
	gs.catalog = CampaignCatalog.new()
	gs.catalog.load_all()
	if gs.catalog.equipment_by_id.size() < 32:
		push_error("catalog size %d" % gs.catalog.equipment_by_id.size())
		quit(2)
		return
	var blade: String = str(gs.grant_equipment_template("eq_n_starter_blade", "smoke"))
	var coat: String = str(gs.grant_equipment_template("eq_ch01_clerk_coat", "smoke"))
	if blade == "" or coat == "":
		push_error("grant failed")
		quit(3)
		return
	if not gs.equip_instance(blade, "H01", "weapon", true):
		push_error("equip blade")
		quit(4)
		return
	if not gs.equip_instance(coat, "H01", "armor", true):
		push_error("equip coat")
		quit(5)
		return
	gs.soft_currency = 5000
	gs.inventory["mat_equipment_scrap"] = 20
	if not gs.upgrade_instance(blade):
		push_error("upgrade")
		quit(6)
		return
	var free: String = str(gs.grant_equipment_template("eq_n_wooden_decree", "smoke"))
	if not gs.salvage_instance(free):
		push_error("salvage")
		quit(7)
		return
	var icon := AssetPaths.equipment_icon("eq_icon_starter_blade")
	if not ResourceLoader.exists(icon):
		push_error("missing icon %s" % icon)
		quit(8)
		return
	print("OK equipment-001 smoke instances=%d blade=%s coat=%s" % [gs.equipment_instances.size(), blade, coat])
	quit(0)
