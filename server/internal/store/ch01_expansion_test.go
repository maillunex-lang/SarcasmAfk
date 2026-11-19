package store_test

import (
	"testing"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

func TestSidequestSQ01AnyOrderIdempotentClaim(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	acc, _ := m.AccountByToken(tok)
	acc.QuestFlags["CH01-Q01"] = true
	_, _ = m.StartSidequest(tok, "CH01-SQ01", "CH01-Q01")

	steps := []string{"sq01_doc_1", "sq01_doc_3", "sq01_doc_2"}
	for _, step := range steps {
		_, reset, err := m.InteractPOI(tok, "POI-02", step, step, "CH01-SQ01", nil, "", false)
		if err != nil || reset {
			t.Fatalf("step %s err=%v reset=%v", step, err, reset)
		}
	}
	defs := map[string]store.EquipmentDef{}
	bundle := store.ExpansionRewardBundle{
		BundleID: "CH01-SQ01-FIRST_CLEAR", Soft: 300,
		Inventory: map[string]int{"mat_hero_exp": 100},
	}
	prog, already, granted, err := m.ClaimSidequest(tok, "CH01-SQ01", steps, bundle, defs, nil, store.EquipmentBalance{})
	if err != nil || already {
		t.Fatalf("claim1 err=%v already=%v", err, already)
	}
	if prog.SoftCurrency < 5300 {
		t.Fatalf("soft=%d", prog.SoftCurrency)
	}
	if granted["soft"] != 300 {
		t.Fatalf("granted=%v", granted)
	}
	_, already2, _, err := m.ClaimSidequest(tok, "CH01-SQ01", steps, bundle, defs, nil, store.EquipmentBalance{})
	if err != nil || !already2 {
		t.Fatalf("claim2 should already err=%v already=%v", err, already2)
	}
}

func TestSQ02SequenceResetAndEquipDEF(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	acc, _ := m.AccountByToken(tok)
	acc.QuestFlags["CH01-Q03"] = true
	_, _ = m.StartSidequest(tok, "CH01-SQ02", "CH01-Q03")
	seq := []string{"sq02_seal_blue", "sq02_seal_gold", "sq02_seal_empty"}

	_, reset, err := m.InteractPOI(tok, "POI-04", "sq02_seal_gold", "sq02_seal_gold", "CH01-SQ02", seq, "", false)
	if err != nil || !reset {
		t.Fatalf("wrong order should reset err=%v reset=%v", err, reset)
	}
	for _, step := range seq {
		_, reset, err = m.InteractPOI(tok, "POI-04", step, step, "CH01-SQ02", seq, "", false)
		if err != nil || reset {
			t.Fatalf("good step %s err=%v reset=%v", step, err, reset)
		}
	}
	defs := map[string]store.EquipmentDef{
		"eq_ch01_clerk_coat": {ItemID: "eq_ch01_clerk_coat", Slot: "armor", Bonuses: map[string]int{"def": 12, "hp": 40}, AccountUnique: true},
	}
	bundle := store.ExpansionRewardBundle{BundleID: "CH01-SQ02-FIRST_CLEAR", Soft: 150, Equipment: []string{"eq_ch01_clerk_coat"}}
	prog, _, _, err := m.ClaimSidequest(tok, "CH01-SQ02", seq, bundle, defs, nil, store.EquipmentBalance{})
	if err != nil {
		t.Fatalf("claim %v", err)
	}
	if prog.Inventory["eq_ch01_clerk_coat"] < 1 {
		t.Fatalf("coat missing inv=%v", prog.Inventory)
	}
	base := store.HeroBaseStats{HP: 1000, Atk: 100, Defense: 80, Speed: 100}
	before := store.ComputePower(base.HP, base.Atk, base.Defense, base.Speed, 1, 0, 0)
	prog, inst, err := m.EquipHeroUnique(tok, "H01", "armor", "eq_ch01_clerk_coat", base, defs)
	if err != nil {
		t.Fatalf("equip %v", err)
	}
	if inst.Equipment["armor"] != "eq_ch01_clerk_coat" {
		t.Fatalf("equip slot=%v", inst.Equipment)
	}
	if inst.Power <= before {
		t.Fatalf("power should rise with DEF gear before=%d after=%d", before, inst.Power)
	}
	hp, atk, def, _ := store.EffectiveCombatStats(base, inst, defs)
	_ = hp
	_ = atk
	if def < 80+12 {
		t.Fatalf("def=%d want>=92", def)
	}
	// unique: cannot leave second copy on H02 without stealing
	_, _, err = m.EquipHeroUnique(tok, "H02", "armor", "eq_ch01_clerk_coat", base, defs)
	if err != nil {
		t.Fatalf("unique reassign should steal ok: %v", err)
	}
	acc2, _ := m.AccountByToken(tok)
	if acc2.HeroInstances["H01"].Equipment["armor"] == "eq_ch01_clerk_coat" {
		t.Fatalf("coat should have moved off H01")
	}
}

func TestSkillUpAffectsCombatATK(t *testing.T) {
	m := store.NewMemory("")
	tok, _ := m.CreateAnonymous()
	base := store.HeroBaseStats{HP: 1000, Atk: 100, Defense: 80, Speed: 100}
	acc, _ := m.AccountByToken(tok)
	_, atk0, _, _ := store.EffectiveCombatStats(base, acc.HeroInstances["H01"], nil)
	_, inst, err := m.SkillUpHero(tok, "H01", "ultimate", base, nil)
	if err != nil {
		t.Fatalf("skill-up %v", err)
	}
	_, atk1, _, _ := store.EffectiveCombatStats(base, inst, nil)
	if atk1 <= atk0 {
		t.Fatalf("atk should rise %d -> %d", atk0, atk1)
	}
	if inst.SkillLevels["ultimate"] != 2 {
		t.Fatalf("ult level=%d", inst.SkillLevels["ultimate"])
	}
}
