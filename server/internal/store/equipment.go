package store

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"math"
	"time"
)

var (
	ErrInvalidSlot      = errors.New(ErrInvalidSlotCode)
	ErrClassRestricted  = errors.New(ErrClassRestrictedCode)
	ErrLevelTooLow      = errors.New(ErrLevelTooLowCode)
	ErrItemLocked       = errors.New(ErrItemLockedCode)
	ErrAlreadyEquipped  = errors.New(ErrAlreadyEquippedCode)
	ErrInventoryFull    = errors.New(ErrInventoryFullCode)
	ErrVersionConflict  = errors.New(ErrVersionConflictCode)
	ErrDuplicateRequest = errors.New(ErrDuplicateRequestCode)
	ErrInvalidTemplate  = errors.New(ErrInvalidTemplateCode)
	ErrConfirmTransfer  = errors.New(ErrConfirmTransferCode)
	ErrEquipNotOwned    = errors.New("NOT_OWNED")
)

// EquipmentInstance is a unique owned item (EQUIPMENT-001).
type EquipmentInstance struct {
	ID                string `json:"id"`
	TemplateID        string `json:"template_id"`
	UpgradeLevel      int    `json:"upgrade_level"`
	IsLocked          bool   `json:"is_locked"`
	EquippedHeroID    string `json:"equipped_hero_id,omitempty"`
	EquippedSlot      string `json:"equipped_slot,omitempty"`
	AcquisitionSource string `json:"acquisition_source,omitempty"`
	AcquiredAt        string `json:"acquired_at,omitempty"`
	Version           int    `json:"version"`
}

// EquipmentTemplate is catalog row.
type EquipmentTemplate struct {
	TemplateID        string         `json:"template_id"`
	DisplayName       string         `json:"display_name"`
	Slot              string         `json:"slot"`
	Rarity            string         `json:"rarity"`
	RequiredHeroLevel int            `json:"required_hero_level"`
	AllowedClasses    []string       `json:"allowed_classes"`
	BaseStats         map[string]int `json:"base_stats"`
	MaxUpgrade        int            `json:"max_upgrade"`
	SetID             string         `json:"set_id"`
	FlavorText        string         `json:"flavor_text"`
	IconAssetID       string         `json:"icon_asset_id"`
	AccountUnique     bool           `json:"account_unique_reward"`
}

// EquipmentSetDef describes 2/4 piece bonuses.
type EquipmentSetDef struct {
	SetID       string
	DisplayName string
	Piece2      map[string]float64
	Piece4      map[string]float64
}

// EquipmentBalance mirrors catalog knobs.
type EquipmentBalance struct {
	UpgradeGrowth          float64
	MaxUpgradeByRarity     map[string]int
	RarityCostMultiplier   map[string]int
	SalvageYieldByRarity   map[string]int
	InventoryCapacity      int
	Aliases                map[string]string
}

const (
	ErrInvalidSlotCode      = "INVALID_SLOT"
	ErrClassRestrictedCode  = "CLASS_RESTRICTED"
	ErrLevelTooLowCode      = "LEVEL_TOO_LOW"
	ErrItemLockedCode       = "ITEM_LOCKED"
	ErrAlreadyEquippedCode  = "ALREADY_EQUIPPED"
	ErrInventoryFullCode    = "INVENTORY_FULL"
	ErrVersionConflictCode  = "VERSION_CONFLICT"
	ErrDuplicateRequestCode = "DUPLICATE_REQUEST"
	ErrInvalidTemplateCode  = "INVALID_TEMPLATE"
	ErrConfirmTransferCode  = "CONFIRM_TRANSFER_REQUIRED"
	DefaultEquipCapacity    = 200
)

func newEquipmentInstanceID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	// UUID-ish hex
	return fmt.Sprintf("%s-%s-%s-%s-%s",
		hex.EncodeToString(b[0:4]),
		hex.EncodeToString(b[4:6]),
		hex.EncodeToString(b[6:8]),
		hex.EncodeToString(b[8:10]),
		hex.EncodeToString(b[10:16]),
	)
}

func EnsureEquipment(acc *AccountProgress) {
	EnsureHeroInstances(acc)
	if acc.EquipmentBag == nil {
		acc.EquipmentBag = map[string]*EquipmentInstance{}
	}
	if acc.EquipmentPending == nil {
		acc.EquipmentPending = []map[string]any{}
	}
	if acc.Idempotency == nil {
		acc.Idempotency = map[string]map[string]any{}
	}
}

func ResolveTemplateID(id string, aliases map[string]string) string {
	if aliases != nil {
		if v, ok := aliases[id]; ok && v != "" {
			return v
		}
	}
	return id
}

func FlatStatBonus(base int, upgrade int, growth float64) int {
	if growth <= 0 {
		growth = 0.10
	}
	return int(math.Floor(float64(base) * (1.0 + growth*float64(upgrade))))
}

func TemplateStatsAtUpgrade(tpl EquipmentTemplate, upgrade int, growth float64) map[string]int {
	out := map[string]int{}
	for k, v := range tpl.BaseStats {
		out[k] = FlatStatBonus(v, upgrade, growth)
	}
	return out
}

func CountSetPieces(acc *AccountProgress, heroID string, templates map[string]EquipmentTemplate) map[string]int {
	EnsureEquipment(acc)
	counts := map[string]int{}
	inst := acc.HeroInstances[heroID]
	if inst == nil || inst.Equipment == nil {
		return counts
	}
	for _, iid := range inst.Equipment {
		if iid == "" {
			continue
		}
		eq := acc.EquipmentBag[iid]
		if eq == nil {
			continue
		}
		tpl, ok := templates[eq.TemplateID]
		if !ok || tpl.SetID == "" {
			continue
		}
		counts[tpl.SetID]++
	}
	return counts
}

func ApplySetBonuses(flat map[string]int, counts map[string]int, sets map[string]EquipmentSetDef) map[string]float64 {
	pct := map[string]float64{"hp": 0, "atk": 0, "defense": 0, "speed": 0}
	for setID, n := range counts {
		def, ok := sets[setID]
		if !ok {
			continue
		}
		if n >= 2 {
			for k, v := range def.Piece2 {
				pct[normalizePctKey(k)] += v
			}
		}
		if n >= 4 {
			for k, v := range def.Piece4 {
				pct[normalizePctKey(k)] += v
			}
		}
	}
	_ = flat
	return pct
}

func normalizePctKey(k string) string {
	switch k {
	case "hp_pct", "hp":
		return "hp"
	case "atk_pct", "atk":
		return "atk"
	case "defense_pct", "def_pct", "defense", "def":
		return "defense"
	case "speed_pct", "speed":
		return "speed"
	default:
		return k
	}
}

// ComputeHeroGearFlat sums equipped instance flat stats (+upgrade) then applies set % on top.
func ComputeHeroGearFlat(acc *AccountProgress, heroID string, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, growth float64) (flat map[string]int, pct map[string]float64, setCounts map[string]int) {
	EnsureEquipment(acc)
	flat = map[string]int{}
	inst := acc.HeroInstances[heroID]
	if inst == nil || inst.Equipment == nil {
		return flat, map[string]float64{}, map[string]int{}
	}
	for _, iid := range inst.Equipment {
		if iid == "" {
			continue
		}
		eq := acc.EquipmentBag[iid]
		if eq == nil {
			// legacy: slot still holds template id
			tplID := ResolveTemplateID(iid, nil)
			if tpl, ok := templates[tplID]; ok {
				for k, v := range tpl.BaseStats {
					flat[k] += v
				}
			}
			continue
		}
		tpl, ok := templates[eq.TemplateID]
		if !ok {
			continue
		}
		for k, v := range TemplateStatsAtUpgrade(tpl, eq.UpgradeLevel, growth) {
			flat[k] += v
		}
	}
	setCounts = CountSetPieces(acc, heroID, templates)
	pct = ApplySetBonuses(flat, setCounts, sets)
	return flat, pct, setCounts
}

func ApplyPctToBase(base, flat map[string]int, pct map[string]float64) map[string]int {
	out := map[string]int{}
	keys := []string{"hp", "atk", "defense", "speed"}
	for _, k := range keys {
		v := base[k] + flat[k]
		out[k] = int(math.Floor(float64(v) * (1.0 + pct[k])))
	}
	return out
}

func EffectiveHeroCombatFromGear(base HeroBaseStats, acc *AccountProgress, heroID string, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, growth float64) (hp, atk, def, spd int) {
	EnsureEquipment(acc)
	inst := acc.HeroInstances[heroID]
	if inst == nil {
		inst = NewHeroInstance(heroID)
	}
	flat, pct, _ := ComputeHeroGearFlat(acc, heroID, templates, sets, growth)
	baseMap := map[string]int{"hp": base.HP, "atk": base.Atk, "defense": base.Defense, "speed": base.Speed}
	final := ApplyPctToBase(baseMap, flat, pct)
	hp, atk, def, spd = final["hp"], final["atk"], final["defense"], final["speed"]
	lvlMul := 1.0 + LevelStatBonusDraft*float64(max(0, inst.Level-1))
	hp = int(float64(hp) * lvlMul)
	atk = int(float64(atk) * lvlMul)
	def = int(float64(def) * lvlMul)
	spd = int(float64(spd) * lvlMul)
	if inst.SkillLevels != nil {
		if ult := inst.SkillLevels["ultimate"]; ult > 1 {
			atk += (ult - 1) * 8
		}
		if basic := inst.SkillLevels["basic"]; basic > 1 {
			atk += (basic - 1) * 4
		}
	}
	return
}

func CreateEquipmentInstance(acc *AccountProgress, templateID, source string, capacity int, templates map[string]EquipmentTemplate) (*EquipmentInstance, error) {
	EnsureEquipment(acc)
	if capacity <= 0 {
		capacity = DefaultEquipCapacity
	}
	tpl, ok := templates[templateID]
	if !ok {
		return nil, ErrInvalidTemplate
	}
	if tpl.AccountUnique {
		for _, eq := range acc.EquipmentBag {
			if eq != nil && eq.TemplateID == templateID {
				return eq, nil // idempotent unique reward
			}
		}
	}
	if len(acc.EquipmentBag) >= capacity {
		acc.EquipmentPending = append(acc.EquipmentPending, map[string]any{
			"template_id": templateID,
			"source":      source,
			"created_at":  nowRFC3339(),
		})
		return nil, ErrInventoryFull
	}
	inst := &EquipmentInstance{
		ID:                newEquipmentInstanceID(),
		TemplateID:        templateID,
		UpgradeLevel:      0,
		AcquisitionSource: source,
		AcquiredAt:        nowRFC3339(),
		Version:           1,
	}
	acc.EquipmentBag[inst.ID] = inst
	return inst, nil
}

func classAllowed(tpl EquipmentTemplate, heroClass string) bool {
	if len(tpl.AllowedClasses) == 0 {
		return true
	}
	for _, c := range tpl.AllowedClasses {
		if c == heroClass {
			return true
		}
	}
	return false
}

func EquipInstance(acc *AccountProgress, instanceID, heroID, slot string, confirmTransfer bool, expectedVersion int, heroLevel int, heroClass string, templates map[string]EquipmentTemplate) (*EquipmentInstance, error) {
	EnsureEquipment(acc)
	valid := map[string]bool{"weapon": true, "armor": true, "accessory": true, "relic": true}
	if !valid[slot] {
		return nil, ErrInvalidSlot
	}
	eq := acc.EquipmentBag[instanceID]
	if eq == nil {
		return nil, ErrEquipNotOwned
	}
	if expectedVersion > 0 && eq.Version != expectedVersion {
		return nil, ErrVersionConflict
	}
	tpl, ok := templates[eq.TemplateID]
	if !ok {
		return nil, ErrInvalidTemplate
	}
	if tpl.Slot != slot {
		return nil, ErrInvalidSlot
	}
	if heroLevel < tpl.RequiredHeroLevel {
		return nil, ErrLevelTooLow
	}
	if !classAllowed(tpl, heroClass) {
		return nil, ErrClassRestricted
	}
	if !acc.OwnedHeroes[heroID] {
		return nil, ErrNotOwned
	}
	if eq.EquippedHeroID != "" && eq.EquippedHeroID != heroID && !confirmTransfer {
		return nil, ErrConfirmTransfer
	}
	// unequip from previous hero
	if eq.EquippedHeroID != "" {
		if prev := acc.HeroInstances[eq.EquippedHeroID]; prev != nil && prev.Equipment != nil {
			if prev.Equipment[eq.EquippedSlot] == instanceID {
				prev.Equipment[eq.EquippedSlot] = ""
			}
		}
	}
	hi := acc.HeroInstances[heroID]
	if hi == nil {
		hi = NewHeroInstance(heroID)
		acc.HeroInstances[heroID] = hi
	}
	if hi.Equipment == nil {
		hi.Equipment = map[string]string{"weapon": "", "armor": "", "accessory": "", "relic": ""}
	}
	// return previous item in slot to inventory (unequipped)
	if oldID := hi.Equipment[slot]; oldID != "" && oldID != instanceID {
		if old := acc.EquipmentBag[oldID]; old != nil {
			old.EquippedHeroID = ""
			old.EquippedSlot = ""
			old.Version++
			old.UpdatedStamp()
		}
	}
	hi.Equipment[slot] = instanceID
	eq.EquippedHeroID = heroID
	eq.EquippedSlot = slot
	eq.Version++
	eq.UpdatedStamp()
	return eq, nil
}

func (e *EquipmentInstance) UpdatedStamp() {
	// no separate UpdatedAt field required for JSONB map; version bump is enough
	_ = time.Now()
}

func UnequipInstance(acc *AccountProgress, instanceID string, expectedVersion int) (*EquipmentInstance, error) {
	EnsureEquipment(acc)
	eq := acc.EquipmentBag[instanceID]
	if eq == nil {
		return nil, ErrEquipNotOwned
	}
	if expectedVersion > 0 && eq.Version != expectedVersion {
		return nil, ErrVersionConflict
	}
	if eq.EquippedHeroID != "" {
		if hi := acc.HeroInstances[eq.EquippedHeroID]; hi != nil && hi.Equipment != nil {
			if hi.Equipment[eq.EquippedSlot] == instanceID {
				hi.Equipment[eq.EquippedSlot] = ""
			}
		}
	}
	eq.EquippedHeroID = ""
	eq.EquippedSlot = ""
	eq.Version++
	return eq, nil
}

func UpgradeInstance(acc *AccountProgress, instanceID string, expectedVersion int, bal EquipmentBalance, templates map[string]EquipmentTemplate) (*EquipmentInstance, map[string]any, error) {
	EnsureEquipment(acc)
	eq := acc.EquipmentBag[instanceID]
	if eq == nil {
		return nil, nil, ErrEquipNotOwned
	}
	if expectedVersion > 0 && eq.Version != expectedVersion {
		return nil, nil, ErrVersionConflict
	}
	tpl, ok := templates[eq.TemplateID]
	if !ok {
		return nil, nil, ErrInvalidTemplate
	}
	maxU := tpl.MaxUpgrade
	if maxU <= 0 {
		maxU = bal.MaxUpgradeByRarity[tpl.Rarity]
	}
	if eq.UpgradeLevel >= maxU {
		return nil, nil, ErrLevelCap
	}
	mult := bal.RarityCostMultiplier[tpl.Rarity]
	if mult <= 0 {
		mult = 1
	}
	softCost := 100 * (eq.UpgradeLevel + 1) * mult
	scrap := 0
	if tpl.Rarity != "N" {
		scrap = 1 + eq.UpgradeLevel/2
	}
	if acc.SoftCurrency < softCost {
		return nil, nil, ErrInsufficient
	}
	if scrap > 0 && acc.Inventory["mat_equipment_scrap"] < scrap {
		return nil, nil, ErrInsufficient
	}
	acc.SoftCurrency -= softCost
	if scrap > 0 {
		acc.Inventory["mat_equipment_scrap"] -= scrap
	}
	eq.UpgradeLevel++
	eq.Version++
	cost := map[string]any{"soft": softCost, "mat_equipment_scrap": scrap}
	return eq, cost, nil
}

func LockInstance(acc *AccountProgress, instanceID string, locked bool, expectedVersion int) (*EquipmentInstance, error) {
	EnsureEquipment(acc)
	eq := acc.EquipmentBag[instanceID]
	if eq == nil {
		return nil, ErrEquipNotOwned
	}
	if expectedVersion > 0 && eq.Version != expectedVersion {
		return nil, ErrVersionConflict
	}
	eq.IsLocked = locked
	eq.Version++
	return eq, nil
}

func SalvageInstance(acc *AccountProgress, instanceID string, expectedVersion int, bal EquipmentBalance, templates map[string]EquipmentTemplate) (map[string]any, error) {
	EnsureEquipment(acc)
	eq := acc.EquipmentBag[instanceID]
	if eq == nil {
		return nil, ErrEquipNotOwned
	}
	if expectedVersion > 0 && eq.Version != expectedVersion {
		return nil, ErrVersionConflict
	}
	if eq.IsLocked {
		return nil, ErrItemLocked
	}
	if eq.EquippedHeroID != "" {
		return nil, ErrAlreadyEquipped
	}
	tpl, ok := templates[eq.TemplateID]
	if !ok {
		return nil, ErrInvalidTemplate
	}
	if tpl.Rarity == "Mythic" {
		return nil, ErrValidation
	}
	yield := bal.SalvageYieldByRarity[tpl.Rarity]
	if yield <= 0 {
		return nil, ErrValidation
	}
	acc.Inventory["mat_equipment_scrap"] += yield
	delete(acc.EquipmentBag, instanceID)
	return map[string]any{"mat_equipment_scrap": yield}, nil
}

// MigrateLegacyEquipment converts inventory stacks / hero slot template IDs into instances (idempotent).
func MigrateLegacyEquipment(acc *AccountProgress, templates map[string]EquipmentTemplate, aliases map[string]string, capacity int) int {
	EnsureEquipment(acc)
	created := 0
	// Convert inventory stack counts for known templates into instances
	for rawID, count := range acc.Inventory {
		tplID := ResolveTemplateID(rawID, aliases)
		if _, ok := templates[tplID]; !ok {
			continue
		}
		if count <= 0 {
			continue
		}
		// already have enough instances of this template?
		have := 0
		for _, eq := range acc.EquipmentBag {
			if eq != nil && eq.TemplateID == tplID && eq.EquippedHeroID == "" {
				have++
			}
		}
		need := count - have
		for i := 0; i < need; i++ {
			inst, err := CreateEquipmentInstance(acc, tplID, "legacy_inventory", capacity, templates)
			if err != nil {
				break
			}
			if inst != nil {
				created++
			}
		}
		// keep material stacks; equipment stacks zeroed after migration into instances
		delete(acc.Inventory, rawID)
	}
	// Convert hero slots that still hold template IDs
	for hid, hi := range acc.HeroInstances {
		if hi == nil || hi.Equipment == nil {
			continue
		}
		for slot, val := range hi.Equipment {
			if val == "" {
				continue
			}
			if acc.EquipmentBag[val] != nil {
				continue // already instance id
			}
			tplID := ResolveTemplateID(val, aliases)
			if _, ok := templates[tplID]; !ok {
				continue
			}
			inst, err := CreateEquipmentInstance(acc, tplID, "legacy_equipped:"+hid, capacity, templates)
			if err != nil || inst == nil {
				continue
			}
			inst.EquippedHeroID = hid
			inst.EquippedSlot = slot
			hi.Equipment[slot] = inst.ID
			created++
		}
	}
	return created
}
