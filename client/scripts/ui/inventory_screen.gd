extends "res://scripts/ui/screen_base.gd"

const TABS := ["Все", "Оружие", "Доспехи", "Аксессуары", "Реликвии", "Материалы"]
const SLOT_BY_TAB := {"Оружие": "weapon", "Доспехи": "armor", "Аксессуары": "accessory", "Реликвии": "relic"}
const UI_EMPTY := "Здесь пока пусто. Даже инструкция не задержалась."
const UI_EQUIPPED := "Экипировка обновлена. Статистика одобряет."
const UI_LEVEL := "Герою нужен уровень {level}. Регламент непреклонен."
const UI_CLASS := "Этот предмет предназначен для другого класса."
const UI_TRANSFER := "Предмет уже используется героем {hero}. Перенести?"
const UI_NO_RES := "Материалов не хватает. Запрос на чудо отклонён."
const UI_UPGRADED := "Усиление +{level}. Отчёт о мощи обновлён."
const UI_LOCKED := "Предмет защищён от случайного разбора."
const UI_SALVAGE := "Разобрать {item}? Действие нельзя отменить."
const UI_FULL := "Инвентарь заполнен. Награда сохранена для получения."

var _tab: String = "Все"
var _list: VBoxContainer
var _status: Label
var _selected_hero: String = "H01"
var _detail: VBoxContainer


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_HEROES)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Арсенал", 36, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Уникальные экземпляры · 4 слота · комплекты", 18, DesignTokens.COLOR_TEXT_MUTED))

	_status = DesignTokens.make_label("", 18, DesignTokens.COLOR_ACCENT_CYAN, HORIZONTAL_ALIGNMENT_LEFT)
	vbox.add_child(_status)

	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 8)
	vbox.add_child(hero_row)
	for hid in GameState.party_ids:
		if str(hid) == "":
			continue
		var hb := DesignTokens.make_button(str(hid), false)
		hb.custom_minimum_size = Vector2(96, 56)
		var capture := str(hid)
		hb.pressed.connect(func() -> void:
			_selected_hero = capture
			_refresh()
		)
		hero_row.add_child(hb)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_row)
	for t in TABS:
		var tb := DesignTokens.make_button(str(t), false)
		tb.custom_minimum_size = Vector2(0, 56)
		var capture_t := str(t)
		tb.pressed.connect(func() -> void:
			_tab = capture_t
			_refresh()
		)
		tab_row.add_child(tb)

	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 8)
	vbox.add_child(_detail)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)

	_sync_from_api()
	_refresh()


func _sync_from_api() -> void:
	if GameState.api == null:
		return
	var inv := GameState.api.equipment_inventory()
	if bool(inv.get("ok", false)) and not bool(inv.get("mock", false)):
		GameState.equipment_instances.clear()
		for raw in inv.get("instances", []):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var d: Dictionary = raw
			var iid := str(d.get("id", ""))
			if iid == "":
				continue
			GameState.equipment_instances[iid] = d
		var mats: Dictionary = inv.get("materials", {})
		if mats.has("mat_equipment_scrap"):
			GameState.inventory["mat_equipment_scrap"] = int(mats.get("mat_equipment_scrap", 0))
		if inv.has("soft_currency"):
			GameState.soft_currency = int(inv.get("soft_currency", GameState.soft_currency))


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for c in _detail.get_children():
		c.queue_free()

	_detail.add_child(DesignTokens.make_label("Герой: %s" % _selected_hero, 24, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	_detail.add_child(_hero_slots_panel(_selected_hero))

	var count := GameState.equipment_instances.size()
	_detail.add_child(DesignTokens.make_label("Инвентарь: %d / 200" % count, 18, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	if _tab == "Материалы":
		_list.add_child(_material_row("mat_equipment_scrap", "Обломки Регламента", int(GameState.inventory.get("mat_equipment_scrap", 0))))
		for k in GameState.inventory.keys():
			if str(k).begins_with("mat_") and str(k) != "mat_equipment_scrap":
				_list.add_child(_material_row(str(k), str(k), int(GameState.inventory[k])))
		if _list.get_child_count() == 0:
			_list.add_child(DesignTokens.make_label(UI_EMPTY, 20, DesignTokens.COLOR_TEXT_MUTED))
		return

	var filter_slot := str(SLOT_BY_TAB.get(_tab, ""))
	var shown := 0
	var ids: Array = GameState.equipment_instances.keys()
	ids.sort()
	for iid in ids:
		var inst: Dictionary = GameState.equipment_instances[iid]
		var tid := str(inst.get("template_id", ""))
		var def: Dictionary = GameState.catalog.get_equipment(tid) if GameState.catalog != null else {}
		var slot := str(def.get("slot", ""))
		if filter_slot != "" and slot != filter_slot:
			continue
		_list.add_child(_instance_card(str(iid), inst, def))
		shown += 1
	if shown == 0:
		_list.add_child(DesignTokens.make_label(UI_EMPTY, 20, DesignTokens.COLOR_TEXT_MUTED))


func _hero_slots_panel(hero_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 12))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var eq: Dictionary = GameState.equipment.get(hero_id, {"weapon": "", "armor": "", "accessory": "", "relic": ""})
	for slot in ["weapon", "armor", "accessory", "relic"]:
		var ref := str(eq.get(slot, ""))
		var label := "—"
		var icon_id := ""
		if ref != "" and GameState.equipment_instances.has(ref):
			var inst: Dictionary = GameState.equipment_instances[ref]
			var tid := str(inst.get("template_id", ""))
			var def: Dictionary = GameState.catalog.get_equipment(tid) if GameState.catalog != null else {}
			label = "%s +%d" % [str(def.get("display_name", def.get("title", tid))), int(inst.get("upgrade_level", 0))]
			icon_id = str(def.get("icon_asset_id", ""))
		elif ref != "":
			label = ref
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(48, 48)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture = AssetPaths.tex(AssetPaths.equipment_icon(icon_id) if icon_id != "" else AssetPaths.ICON_INVENTORY)
		row.add_child(ic)
		row.add_child(DesignTokens.make_label("%s: %s" % [slot, label], 18, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
		box.add_child(row)
	return panel


func _material_row(id: String, title: String, qty: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(64, 64)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture = AssetPaths.tex(AssetPaths.ICON_MAT_EQUIPMENT_SCRAP if id == "mat_equipment_scrap" else AssetPaths.ICON_INVENTORY)
	row.add_child(ic)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	box.add_child(DesignTokens.make_label(title, 22, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(DesignTokens.make_label("%s × %d" % [id, qty], 18, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	return panel


func _instance_card(iid: String, inst: Dictionary, def: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 12))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)

	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(96, 96)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture = AssetPaths.tex(AssetPaths.equipment_icon(str(def.get("icon_asset_id", ""))))
	row.add_child(ic)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	var name := str(def.get("display_name", def.get("title", inst.get("template_id", "?"))))
	var rarity := str(def.get("rarity", "?"))
	var slot := str(def.get("slot", "?"))
	var lvl := int(inst.get("upgrade_level", 0))
	box.add_child(DesignTokens.make_label("%s · %s · +%d" % [name, rarity, lvl], 22, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(DesignTokens.make_label(str(def.get("flavor_text", def.get("description", ""))), 16, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var stats: Dictionary = def.get("base_stats", def.get("bonuses", {}))
	box.add_child(DesignTokens.make_label("Слот %s · %s" % [slot, _stats_text(stats, lvl)], 16, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
	var eq_hero := str(inst.get("equipped_hero_id", ""))
	if eq_hero != "":
		box.add_child(DesignTokens.make_label("Надето: %s / %s" % [eq_hero, str(inst.get("equipped_slot", ""))], 16, DesignTokens.COLOR_ACCENT_CYAN, HORIZONTAL_ALIGNMENT_LEFT))
	if bool(inst.get("is_locked", false)):
		box.add_child(DesignTokens.make_label(UI_LOCKED, 16, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	root.add_child(btns)

	var equip_btn := DesignTokens.make_button("Надеть", true)
	equip_btn.custom_minimum_size = Vector2(0, 64)
	equip_btn.pressed.connect(func() -> void: _do_equip(iid, inst, def))
	btns.add_child(equip_btn)

	var unequip_btn := DesignTokens.make_button("Снять", false)
	unequip_btn.custom_minimum_size = Vector2(0, 64)
	unequip_btn.pressed.connect(func() -> void: _do_unequip(iid, inst))
	btns.add_child(unequip_btn)

	var up_btn := DesignTokens.make_button("Улучшить", false)
	up_btn.custom_minimum_size = Vector2(0, 64)
	up_btn.pressed.connect(func() -> void: _do_upgrade(iid, inst))
	btns.add_child(up_btn)

	var lock_btn := DesignTokens.make_button("Защитить" if not bool(inst.get("is_locked", false)) else "Снять защиту", false)
	lock_btn.custom_minimum_size = Vector2(0, 64)
	lock_btn.pressed.connect(func() -> void: _do_lock(iid, not bool(inst.get("is_locked", false))))
	btns.add_child(lock_btn)

	var salvage_btn := DesignTokens.make_button("Разобрать", false)
	salvage_btn.custom_minimum_size = Vector2(0, 64)
	salvage_btn.pressed.connect(func() -> void: _do_salvage(iid, name, inst))
	btns.add_child(salvage_btn)
	return panel


func _stats_text(stats: Dictionary, upgrade: int) -> String:
	var parts: PackedStringArray = []
	for k in ["hp", "atk", "defense", "def", "speed"]:
		if not stats.has(k):
			continue
		var base := int(stats[k])
		var val := int(floor(float(base) * (1.0 + 0.10 * float(upgrade))))
		parts.append("%s %d" % [k.to_upper(), val])
	return ", ".join(parts)


func _do_equip(iid: String, inst: Dictionary, def: Dictionary) -> void:
	var slot := str(def.get("slot", "weapon"))
	var ver := int(inst.get("version", 0))
	var res: Dictionary = GameState.api.equipment_equip(iid, _selected_hero, slot, true, ver)
	if bool(res.get("ok", false)):
		_status.text = UI_EQUIPPED
		if res.has("progress"):
			_apply_progress(res.get("progress", {}))
		elif bool(res.get("mock", false)):
			pass
		_sync_from_api()
		_refresh()
	else:
		var err := str(res.get("error", "EQUIP_FAILED"))
		if err == "LEVEL_TOO_LOW":
			_status.text = UI_LEVEL.replace("{level}", str(def.get("required_hero_level", "?")))
		elif err == "CLASS_RESTRICTED":
			_status.text = UI_CLASS
		elif err == "CONFIRM_TRANSFER_REQUIRED":
			_status.text = UI_TRANSFER.replace("{hero}", str(inst.get("equipped_hero_id", "?")))
		else:
			_status.text = "Ошибка: %s" % err


func _do_unequip(iid: String, inst: Dictionary) -> void:
	var res: Dictionary = GameState.api.equipment_unequip(iid, int(inst.get("version", 0)))
	if bool(res.get("ok", false)):
		_status.text = "Снято."
		_sync_from_api()
		_refresh()
	else:
		_status.text = "Связь прервалась. Проверь, сохранилось ли действие."


func _do_upgrade(iid: String, inst: Dictionary) -> void:
	var res: Dictionary = GameState.api.equipment_upgrade(iid, int(inst.get("version", 0)))
	if bool(res.get("ok", false)):
		_sync_from_api()
		var fresh: Dictionary = GameState.equipment_instances.get(iid, inst)
		_status.text = UI_UPGRADED.replace("{level}", str(fresh.get("upgrade_level", "?")))
		_refresh()
	else:
		_status.text = UI_NO_RES


func _do_lock(iid: String, locked: bool) -> void:
	var ver := int(GameState.equipment_instances.get(iid, {}).get("version", 0))
	var res: Dictionary = GameState.api.equipment_lock(iid, locked, ver)
	if bool(res.get("ok", false)):
		_status.text = UI_LOCKED if locked else "Защита снята."
		_sync_from_api()
		_refresh()


func _do_salvage(iid: String, item_name: String, inst: Dictionary) -> void:
	_status.text = UI_SALVAGE.replace("{item}", item_name)
	var res: Dictionary = GameState.api.equipment_salvage(iid, int(inst.get("version", 0)))
	if bool(res.get("ok", false)):
		_status.text = "Разобрано."
		_sync_from_api()
		_refresh()
	else:
		var err := str(res.get("error", ""))
		if err == "ITEM_LOCKED":
			_status.text = UI_LOCKED
		else:
			_status.text = "Разбор отклонён."


func _apply_progress(prog: Variant) -> void:
	if typeof(prog) != TYPE_DICTIONARY:
		return
	var p: Dictionary = prog
	if p.has("soft_currency"):
		GameState.soft_currency = int(p.get("soft_currency", GameState.soft_currency))
	if p.has("equipment_instances"):
		var ei = p.get("equipment_instances", {})
		if typeof(ei) == TYPE_DICTIONARY:
			GameState.equipment_instances = ei
	if p.has("hero_instances"):
		# sync equipped slots for party
		var hi = p.get("hero_instances", {})
		if typeof(hi) == TYPE_DICTIONARY:
			for hid in hi.keys():
				var h = hi[hid]
				if typeof(h) != TYPE_DICTIONARY:
					continue
				var eq = h.get("equipment", {})
				if typeof(eq) == TYPE_DICTIONARY:
					GameState.equipment[str(hid)] = eq
