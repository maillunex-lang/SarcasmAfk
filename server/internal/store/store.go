package store

// HeroBaseStats are catalog stats used for power recalculation.
type HeroBaseStats struct {
	HP      int
	Atk     int
	Defense int
	Speed   int
}

// Store is the account/progress backend (memory, postgres, …).
type Store interface {
	CreateAnonymous() (token string, progress AccountProgress)
	AccountByToken(token string) (*AccountProgress, error)
	SetParty(token string, party []string) (*AccountProgress, error)
	ClaimReward(token, bundleID string, soft, xp int) (softDelta, xpDelta int, already bool, err error)
	ClaimAFK(token string, softPerHour, xpPerHour int) (hours float64, soft, xp int, err error)
	Summon(token string, heroPool []string) (heroID string, newly bool, err error)
	StartBattle(token, battleID string, party []string) (seed int64, err error)
	AppendBattleCommand(token, battleID string, cmd BattleCommand) (*AccountProgress, error)
	FinishBattle(token, battleID string, victory bool) (*AccountProgress, error)
	LevelUpHero(token, heroID string, levels int, base HeroBaseStats) (*AccountProgress, *HeroInstance, error)
	StarUpHero(token, heroID string, base HeroBaseStats) (*AccountProgress, *HeroInstance, error)
	EquipHero(token, heroID, slot, itemID string, base HeroBaseStats) (*AccountProgress, *HeroInstance, error)
	SkillUpHero(token, heroID, skillID string, base HeroBaseStats, defs map[string]EquipmentDef) (*AccountProgress, *HeroInstance, error)
	EquipHeroUnique(token, heroID, slot, itemID string, base HeroBaseStats, defs map[string]EquipmentDef) (*AccountProgress, *HeroInstance, error)
	StartSidequest(token, questID, requiredMain string) (*AccountProgress, error)
	InteractPOI(token, poiID, actionID, stepID, sidequestID string, sequence []string, completionFlag string, oneTime bool) (*AccountProgress, bool, error)
	ClaimSidequest(token, questID string, requiredSteps []string, bundle ExpansionRewardBundle, defs map[string]EquipmentDef, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, bool, map[string]any, error)
	EquipInstance(token, instanceID, heroID, slot string, confirmTransfer bool, expectedVersion int, requestID string, base HeroBaseStats, heroClass string, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, map[string]any, error)
	UnequipInstance(token, instanceID string, expectedVersion int, requestID string) (*AccountProgress, *EquipmentInstance, error)
	UpgradeInstance(token, instanceID string, expectedVersion int, requestID string, base HeroBaseStats, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, map[string]any, error)
	LockInstance(token, instanceID string, locked bool, expectedVersion int, requestID string) (*AccountProgress, *EquipmentInstance, error)
	SalvageInstance(token, instanceID string, expectedVersion int, requestID string, confirm bool, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, map[string]any, error)
	GrantEquipmentReward(token, rewardKey, templateID, source string, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, error)
	MigrateLegacyEquipment(token string, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, int, error)
	ApplySimulatedPurchase(token, sku string, soft, hard, tickets int, inventory map[string]int) (*AccountProgress, bool, error)
	SpendSoft(token string, amount int) (*AccountProgress, error)
	SummonBanner(token, bannerID string, count int, poolByRarity map[string][]string) (*AccountProgress, []GachaPullResult, error)
	TestPurchase(token, sku string, soft, hard, tickets, vipPoints int, inventory map[string]int) (*AccountProgress, map[string]any, error)
	ClaimVIPDaily(token string, soft, tickets int) (*AccountProgress, bool, error)
}

// Ensure implementations satisfy the interface at compile time.
var (
	_ Store = (*Memory)(nil)
)
