package store_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func testTemplates() map[string]store.EquipmentTemplate {
	return map[string]store.EquipmentTemplate{
		"eq_n_starter_blade": {
			TemplateID: "eq_n_starter_blade", Slot: "weapon", Rarity: "N",
			RequiredHeroLevel: 1, BaseStats: map[string]int{"atk": 10}, MaxUpgrade: 3,
		},
		"eq_ch01_clerk_coat": {
			TemplateID: "eq_ch01_clerk_coat", Slot: "armor", Rarity: "R",
			RequiredHeroLevel: 1, BaseStats: map[string]int{"hp": 60, "defense": 10}, MaxUpgrade: 5,
			AccountUnique: true,
		},
		"eq_r_queue_cutter": {
			TemplateID: "eq_r_queue_cutter", Slot: "weapon", Rarity: "R",
			RequiredHeroLevel: 3, BaseStats: map[string]int{"atk": 16}, MaxUpgrade: 5,
			SetID: "set_queue_guard",
		},
		"eq_r_clerk_coat": {
			TemplateID: "eq_r_clerk_coat", Slot: "armor", Rarity: "R",
			RequiredHeroLevel: 3, BaseStats: map[string]int{"hp": 65, "defense": 9}, MaxUpgrade: 5,
			SetID: "set_queue_guard",
		},
		"eq_r_queue_badge": {
			TemplateID: "eq_r_queue_badge", Slot: "accessory", Rarity: "R",
			RequiredHeroLevel: 3, BaseStats: map[string]int{"hp": 35, "defense": 4}, MaxUpgrade: 5,
			SetID: "set_queue_guard",
		},
		"eq_r_queue_token": {
			TemplateID: "eq_r_queue_token", Slot: "relic", Rarity: "R",
			RequiredHeroLevel: 3, BaseStats: map[string]int{"hp": 40, "defense": 5}, MaxUpgrade: 5,
			SetID: "set_queue_guard",
		},
		"eq_r_ink_quill": {
			TemplateID: "eq_r_ink_quill", Slot: "weapon", Rarity: "R",
			RequiredHeroLevel: 3, AllowedClasses: []string{"mage", "support"},
			BaseStats: map[string]int{"atk": 15, "speed": 1}, MaxUpgrade: 5,
		},
	}
}

func testBalance() store.EquipmentBalance {
	return store.EquipmentBalance{
		UpgradeGrowth: 0.10,
		MaxUpgradeByRarity: map[string]int{"N": 3, "R": 5, "SR": 8},
		RarityCostMultiplier: map[string]int{"N": 1, "R": 2, "SR": 4},
		SalvageYieldByRarity: map[string]int{"N": 1, "R": 3, "SR": 8},
		InventoryCapacity: 200,
		Aliases: map[string]string{"starter_blade": "eq_n_starter_blade"},
	}
}

func testSets() map[string]store.EquipmentSetDef {
	return map[string]store.EquipmentSetDef{
		"set_queue_guard": {
			SetID: "set_queue_guard", DisplayName: "Страж Очереди",
			Piece2: map[string]float64{"defense_pct": 0.08},
			Piece4: map[string]float64{"hp_pct": 0.10},
		},
	}
}

func TestEquipmentUniqueInstancesAndEquip(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	tpl := testTemplates()
	bal := testBalance()
	sets := testSets()

	_, a, err := m.GrantEquipmentReward(tok, "CH01-B02-EQ-FIRST_CLEAR", "eq_n_starter_blade", "battle:B02", tpl, bal)
	if err != nil || a == nil {
		t.Fatalf("grant1 %v inst=%v", err, a)
	}
	_, b, err := m.GrantEquipmentReward(tok, "dup-key", "eq_n_starter_blade", "drop", tpl, bal)
	if err != nil || b == nil {
		t.Fatalf("grant2 %v", err)
	}
	if a.ID == b.ID {
		t.Fatalf("expected unique UUIDs")
	}
	// first-clear idempotent
	_, a2, err := m.GrantEquipmentReward(tok, "CH01-B02-EQ-FIRST_CLEAR", "eq_n_starter_blade", "battle:B02", tpl, bal)
	if err != nil {
		t.Fatalf("idempotent grant %v", err)
	}
	if a2 != nil && a2.ID != a.ID {
		t.Fatalf("first clear should return same instance")
	}

	base := store.HeroBaseStats{HP: 1000, Atk: 100, Defense: 80, Speed: 100}
	prog, inst, _, err := m.EquipInstance(tok, a.ID, "H01", "weapon", false, a.Version, "req-eq-1", base, "warrior", tpl, sets, bal)
	if err != nil {
		t.Fatalf("equip %v", err)
	}
	if inst.EquippedHeroID != "H01" || prog.HeroInstances["H01"].Equipment["weapon"] != a.ID {
		t.Fatalf("equip state %+v hero=%v", inst, prog.HeroInstances["H01"].Equipment)
	}
	hp0, atk0, _, _ := store.EffectiveCombatStatsFull(prog, base, prog.HeroInstances["H01"], nil, tpl, sets, bal.UpgradeGrowth)
	if atk0 <= 100 {
		t.Fatalf("expected atk bonus got atk=%d hp=%d", atk0, hp0)
	}

	// transfer requires confirm
	_, _, _, err = m.EquipInstance(tok, a.ID, "H02", "weapon", false, inst.Version, "req-eq-2", base, "support", tpl, sets, bal)
	if err != store.ErrConfirmTransfer {
		t.Fatalf("want CONFIRM_TRANSFER got %v", err)
	}
	_, inst2, _, err := m.EquipInstance(tok, a.ID, "H02", "weapon", true, inst.Version, "req-eq-3", base, "support", tpl, sets, bal)
	if err != nil || inst2.EquippedHeroID != "H02" {
		t.Fatalf("transfer %v inst=%+v", err, inst2)
	}
	if prog2, _ := m.AccountByToken(tok); prog2.HeroInstances["H01"].Equipment["weapon"] != "" {
		t.Fatalf("H01 should be empty after transfer")
	}
}

func TestEquipmentUpgradeSalvageLockSets(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	tpl := testTemplates()
	bal := testBalance()
	sets := testSets()
	base := store.HeroBaseStats{HP: 1000, Atk: 100, Defense: 80, Speed: 100}

	acc, _ := m.AccountByToken(tok)
	acc.SoftCurrency = 10000
	acc.Inventory["mat_equipment_scrap"] = 50
	acc.HeroInstances["H01"].Level = 5

	ids := []string{}
	for _, tid := range []string{"eq_r_queue_cutter", "eq_r_clerk_coat", "eq_r_queue_badge", "eq_r_queue_token"} {
		_, inst, err := m.GrantEquipmentReward(tok, "g:"+tid, tid, "test", tpl, bal)
		if err != nil {
			t.Fatalf("grant %s %v", tid, err)
		}
		ids = append(ids, inst.ID)
	}
	slots := []string{"weapon", "armor", "accessory", "relic"}
	for i, id := range ids {
		eq, _ := m.AccountByToken(tok)
		ver := eq.EquipmentBag[id].Version
		_, _, _, err := m.EquipInstance(tok, id, "H01", slots[i], false, ver, "eq"+slots[i], base, "warrior", tpl, sets, bal)
		if err != nil {
			t.Fatalf("equip %s %v", slots[i], err)
		}
	}
	prog, _ := m.AccountByToken(tok)
	_, pct, counts := store.ComputeHeroGearFlat(prog, "H01", tpl, sets, bal.UpgradeGrowth)
	if counts["set_queue_guard"] != 4 {
		t.Fatalf("set count=%v", counts)
	}
	if pct["defense"] < 0.07 || pct["hp"] < 0.09 {
		t.Fatalf("set pct=%v", pct)
	}

	acc, _ = m.AccountByToken(tok)
	bladeID := ids[0]
	ver := acc.EquipmentBag[bladeID].Version
	_, up, extras, err := m.UpgradeInstance(tok, bladeID, ver, "up1", base, tpl, sets, bal)
	if err != nil || up.UpgradeLevel != 1 {
		t.Fatalf("upgrade %v extras=%v", err, extras)
	}
	stats0 := store.TemplateStatsAtUpgrade(tpl["eq_r_queue_cutter"], 0, 0.10)
	stats1 := store.TemplateStatsAtUpgrade(tpl["eq_r_queue_cutter"], 1, 0.10)
	if stats1["atk"] <= stats0["atk"] {
		t.Fatalf("upgrade stats %v -> %v", stats0, stats1)
	}

	// class restriction
	_, quill, err := m.GrantEquipmentReward(tok, "quill", "eq_r_ink_quill", "test", tpl, bal)
	if err != nil {
		t.Fatalf("quill %v", err)
	}
	_, _, _, err = m.EquipInstance(tok, quill.ID, "H01", "weapon", true, quill.Version, "class-fail", base, "warrior", tpl, sets, bal)
	if err != store.ErrClassRestricted {
		t.Fatalf("want CLASS_RESTRICTED got %v", err)
	}

	// salvage locked fails
	acc, _ = m.AccountByToken(tok)
	_, free, err := m.GrantEquipmentReward(tok, "free-blade", "eq_n_starter_blade", "test", tpl, bal)
	if err != nil {
		t.Fatalf("free %v", err)
	}
	_, locked, err := m.LockInstance(tok, free.ID, true, free.Version, "lock1")
	if err != nil || !locked.IsLocked {
		t.Fatalf("lock %v", err)
	}
	_, _, err = m.SalvageInstance(tok, free.ID, locked.Version, "sal1", true, tpl, bal)
	if err != store.ErrItemLocked {
		t.Fatalf("want ITEM_LOCKED got %v", err)
	}
	_, unlocked, err := m.LockInstance(tok, free.ID, false, locked.Version, "unlock1")
	if err != nil {
		t.Fatalf("unlock %v", err)
	}
	prog, reward, err := m.SalvageInstance(tok, free.ID, unlocked.Version, "sal2", true, tpl, bal)
	if err != nil {
		t.Fatalf("salvage %v", err)
	}
	if reward["mat_equipment_scrap"] != 1 {
		t.Fatalf("reward=%v", reward)
	}
	if _, ok := prog.EquipmentBag[free.ID]; ok {
		t.Fatalf("instance should be deleted")
	}
}

func TestLegacyMigrationAliases(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	acc, _ := m.AccountByToken(tok)
	acc.Inventory["starter_blade"] = 1
	acc.HeroInstances["H01"].Equipment["armor"] = "eq_ch01_clerk_coat"
	acc.Inventory["eq_ch01_clerk_coat"] = 1
	tpl := testTemplates()
	bal := testBalance()
	prog, n, err := m.MigrateLegacyEquipment(tok, tpl, bal)
	if err != nil || n < 1 {
		t.Fatalf("migrate n=%d err=%v", n, err)
	}
	if prog.Inventory["starter_blade"] != 0 {
		t.Fatalf("legacy stack not cleared")
	}
	foundBlade := false
	for _, eq := range prog.EquipmentBag {
		if eq.TemplateID == "eq_n_starter_blade" {
			foundBlade = true
		}
	}
	if !foundBlade {
		t.Fatalf("alias blade missing instances=%v", prog.EquipmentBag)
	}
	armorRef := prog.HeroInstances["H01"].Equipment["armor"]
	if prog.EquipmentBag[armorRef] == nil {
		t.Fatalf("equipped armor not instance id=%s", armorRef)
	}
}

func TestSQ02GrantsUniqueInstance(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	acc, _ := m.AccountByToken(tok)
	acc.QuestFlags["CH01-Q03"] = true
	_, _ = m.StartSidequest(tok, "CH01-SQ02", "CH01-Q03")
	seq := []string{"sq02_seal_blue", "sq02_seal_gold", "sq02_seal_empty"}
	for _, step := range seq {
		_, _, _, _ = m.InteractPOI(tok, "POI-04", step, step, "CH01-SQ02", seq, "", false, nil, nil)
	}
	tpl := testTemplates()
	bal := testBalance()
	bundle := store.ExpansionRewardBundle{BundleID: "CH01-SQ02-FIRST_CLEAR", Soft: 150, Equipment: []string{"eq_ch01_clerk_coat"}}
	prog, _, granted, err := m.ClaimSidequest(tok, "CH01-SQ02", seq, bundle, nil, tpl, bal)
	if err != nil {
		t.Fatalf("claim %v", err)
	}
	ids, _ := granted["equipment_instances"].([]string)
	if len(ids) != 1 {
		t.Fatalf("granted=%v", granted)
	}
	eq := prog.EquipmentBag[ids[0]]
	if eq == nil || eq.TemplateID != "eq_ch01_clerk_coat" {
		t.Fatalf("instance=%v", eq)
	}
	base := store.HeroBaseStats{HP: 1000, Atk: 100, Defense: 80, Speed: 100}
	_, inst, _, err := m.EquipInstance(tok, eq.ID, "H01", "armor", false, eq.Version, "sq02-eq", base, "warrior", tpl, testSets(), bal)
	if err != nil {
		t.Fatalf("equip %v", err)
	}
	prog, _ = m.AccountByToken(tok)
	_, _, def, _ := store.EffectiveCombatStatsFull(prog, base, prog.HeroInstances["H01"], nil, tpl, testSets(), bal.UpgradeGrowth)
	if def <= 80 {
		t.Fatalf("DEF should increase got %d hero_eq=%v inst=%v", def, prog.HeroInstances["H01"].Equipment, inst)
	}
}
