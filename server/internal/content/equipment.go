package content

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/maillunex-lang/SarcasmAfk/server/internal/store"
)

type equipmentCatalogFile struct {
	Version               int            `json:"version"`
	BalanceVersion        string         `json:"balance_version"`
	MaxUpgradeByRarity    map[string]int `json:"max_upgrade_by_rarity"`
	RarityCostMultiplier  map[string]int `json:"rarity_cost_multiplier"`
	SalvageYieldByRarity  map[string]int `json:"salvage_yield_by_rarity"`
	InventoryCapacity     int            `json:"inventory_capacity"`
	UpgradeGrowthPerLevel float64        `json:"upgrade_growth_per_level"`
	Aliases               map[string]string `json:"aliases"`
	Templates             []struct {
		TemplateID        string         `json:"template_id"`
		DisplayName       string         `json:"display_name"`
		Slot              string         `json:"slot"`
		Rarity            string         `json:"rarity"`
		RequiredHeroLevel int            `json:"required_hero_level"`
		AllowedClasses    []string       `json:"allowed_classes"`
		BaseStats         map[string]int `json:"base_stats"`
		MaxUpgrade        int            `json:"max_upgrade"`
		SetID             *string        `json:"set_id"`
		FlavorText        string         `json:"flavor_text"`
		IconAssetID       string         `json:"icon_asset_id"`
		AccountUnique     bool           `json:"account_unique_reward"`
	} `json:"templates"`
	CH01Guaranteed []struct {
		Trigger    string `json:"trigger"`
		TemplateID string `json:"template_id"`
		BundleKey  string `json:"bundle_key"`
	} `json:"ch01_guaranteed_rewards"`
	RandomDrop struct {
		Enabled bool `json:"enabled"`
	} `json:"random_drop"`
}

type equipmentSetsFile struct {
	Sets []struct {
		SetID       string             `json:"set_id"`
		DisplayName string             `json:"display_name"`
		Piece2      map[string]any     `json:"piece_2"`
		Piece4      map[string]any     `json:"piece_4"`
	} `json:"sets"`
}

func parsePctMap(raw map[string]any) map[string]float64 {
	out := map[string]float64{}
	for k, v := range raw {
		if k == "status" {
			continue
		}
		switch n := v.(type) {
		case float64:
			out[k] = n
		case int:
			out[k] = float64(n)
		}
	}
	return out
}

func (l *Loader) loadEquipmentCatalog() {
	path := filepath.Join(l.root, "equipment", "equipment_catalog_v1.json")
	b, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var cat equipmentCatalogFile
	if json.Unmarshal(b, &cat) != nil {
		return
	}
	l.eqTemplates = map[string]store.EquipmentTemplate{}
	l.eqAliases = map[string]string{}
	l.eqCH01Rewards = map[string]string{} // bundle_key -> template_id
	for k, v := range cat.Aliases {
		l.eqAliases[k] = v
	}
	for _, t := range cat.Templates {
		setID := ""
		if t.SetID != nil {
			setID = *t.SetID
		}
		stats := t.BaseStats
		if stats == nil {
			stats = map[string]int{}
		}
		classes := t.AllowedClasses
		if classes == nil {
			classes = []string{}
		}
		l.eqTemplates[t.TemplateID] = store.EquipmentTemplate{
			TemplateID: t.TemplateID, DisplayName: t.DisplayName, Slot: t.Slot, Rarity: t.Rarity,
			RequiredHeroLevel: t.RequiredHeroLevel, AllowedClasses: classes, BaseStats: stats,
			MaxUpgrade: t.MaxUpgrade, SetID: setID, FlavorText: t.FlavorText,
			IconAssetID: t.IconAssetID, AccountUnique: t.AccountUnique,
		}
		// Bridge legacy EquipmentDef for CH01 expansion paths.
		bon := map[string]int{}
		for k, v := range stats {
			bon[k] = v
			if k == "defense" {
				bon["def"] = v
			}
		}
		l.equipment[t.TemplateID] = store.EquipmentDef{
			ItemID: t.TemplateID, Slot: t.Slot, Bonuses: bon, AccountUnique: t.AccountUnique,
		}
	}
	// Alias legacy starter_* / ch01 into EquipmentDef
	for alias, canon := range l.eqAliases {
		if tpl, ok := l.eqTemplates[canon]; ok {
			bon := map[string]int{}
			for k, v := range tpl.BaseStats {
				bon[k] = v
				if k == "defense" {
					bon["def"] = v
				}
			}
			l.equipment[alias] = store.EquipmentDef{
				ItemID: alias, Slot: tpl.Slot, Bonuses: bon, AccountUnique: tpl.AccountUnique,
			}
		}
	}
	l.eqBalance = store.EquipmentBalance{
		UpgradeGrowth:        cat.UpgradeGrowthPerLevel,
		MaxUpgradeByRarity:   cat.MaxUpgradeByRarity,
		RarityCostMultiplier: cat.RarityCostMultiplier,
		SalvageYieldByRarity: cat.SalvageYieldByRarity,
		InventoryCapacity:    cat.InventoryCapacity,
		Aliases:              l.eqAliases,
	}
	if l.eqBalance.UpgradeGrowth <= 0 {
		l.eqBalance.UpgradeGrowth = 0.10
	}
	if l.eqBalance.InventoryCapacity <= 0 {
		l.eqBalance.InventoryCapacity = store.DefaultEquipCapacity
	}
	l.eqBalanceVersion = cat.BalanceVersion
	for _, r := range cat.CH01Guaranteed {
		l.eqCH01Rewards[r.BundleKey] = r.TemplateID
		if r.Trigger != "" {
			l.eqCH01Rewards[r.Trigger] = r.TemplateID
		}
	}
	l.eqRandomDropEnabled = cat.RandomDrop.Enabled

	// sets
	l.eqSets = map[string]store.EquipmentSetDef{}
	if sb, err := os.ReadFile(filepath.Join(l.root, "equipment", "equipment_sets.json")); err == nil {
		var sf equipmentSetsFile
		if json.Unmarshal(sb, &sf) == nil {
			for _, s := range sf.Sets {
				def := store.EquipmentSetDef{
					SetID: s.SetID, DisplayName: s.DisplayName,
					Piece2: parsePctMap(s.Piece2), Piece4: parsePctMap(s.Piece4),
				}
				l.eqSets[s.SetID] = def
			}
		}
	}
}

func (l *Loader) EquipmentTemplates() map[string]store.EquipmentTemplate {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]store.EquipmentTemplate{}
	for k, v := range l.eqTemplates {
		out[k] = v
	}
	return out
}

func (l *Loader) EquipmentSets() map[string]store.EquipmentSetDef {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]store.EquipmentSetDef{}
	for k, v := range l.eqSets {
		out[k] = v
	}
	return out
}

func (l *Loader) EquipmentBalance() store.EquipmentBalance {
	l.mu.RLock()
	defer l.mu.RUnlock()
	return l.eqBalance
}

func (l *Loader) EquipmentBalanceVersion() string {
	l.mu.RLock()
	defer l.mu.RUnlock()
	return l.eqBalanceVersion
}

func (l *Loader) EquipmentAliases() map[string]string {
	l.mu.RLock()
	defer l.mu.RUnlock()
	out := map[string]string{}
	for k, v := range l.eqAliases {
		out[k] = v
	}
	return out
}

func (l *Loader) CH01EquipmentReward(key string) (string, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	v, ok := l.eqCH01Rewards[key]
	return v, ok
}

func (l *Loader) EquipmentCatalogPublic() map[string]any {
	l.mu.RLock()
	defer l.mu.RUnlock()
	templates := make([]store.EquipmentTemplate, 0, len(l.eqTemplates))
	for _, t := range l.eqTemplates {
		templates = append(templates, t)
	}
	sets := make([]store.EquipmentSetDef, 0, len(l.eqSets))
	for _, s := range l.eqSets {
		sets = append(sets, s)
	}
	return map[string]any{
		"balance_version": l.eqBalanceVersion,
		"templates":       templates,
		"sets":            sets,
		"balance":         l.eqBalance,
		"aliases":         l.eqAliases,
		"random_drop_enabled": l.eqRandomDropEnabled,
	}
}
