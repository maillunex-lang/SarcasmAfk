package store

import "time"

// AccountProgress matches docs/PHASE0_SPEC.md §3.1 (extended for Phase 2 + online systems).
type BattleCommand struct {
	Op     string `json:"op"`
	UnitID string `json:"unit_id"`
	AtTick int    `json:"at_tick"`
}

// HeroInstance is a player-owned playable hero (not only a catalog row).
type HeroInstance struct {
	CatalogID   string            `json:"catalog_id"`
	Level       int               `json:"level"`
	Stars       int               `json:"stars"`
	AwakenRank  int               `json:"awaken_rank"`
	Fragments   int               `json:"fragments"`
	SkillLevels map[string]int    `json:"skill_levels"`
	Equipment   map[string]string `json:"equipment"`
	Power       int               `json:"power"`
}

type AccountProgress struct {
	AccountID        string                   `json:"account_id"`
	CommanderXP      int                      `json:"commander_xp"`
	SoftCurrency     int                      `json:"soft_currency"`
	HardCurrency     int                      `json:"hard_currency"`
	SummonTickets    int                      `json:"summon_tickets"`
	PartyIDs         []string                 `json:"party_ids"`
	QuestFlags       map[string]bool          `json:"quest_flags"`
	ClaimedRewards   map[string]bool          `json:"claimed_rewards"`
	OwnedHeroes      map[string]bool          `json:"owned_heroes"`
	HeroInstances    map[string]*HeroInstance `json:"hero_instances,omitempty"`
	Inventory        map[string]int           `json:"inventory,omitempty"`
	VipPoints        int                      `json:"vip_points"`
	VipLevel         int                      `json:"vip_level"`
	PityCounters     map[string]int           `json:"pity_counters,omitempty"`
	GachaHistory     []GachaHistoryEntry      `json:"gacha_history,omitempty"`
	TestPurchaseDay  string                   `json:"test_purchase_day,omitempty"`
	TestPurchasesDay int                      `json:"test_purchases_day,omitempty"`
	TestHardDay      int                      `json:"test_hard_day,omitempty"`
	TestVipDay       int                      `json:"test_vip_day,omitempty"`
	VipDailyClaimed  string                   `json:"vip_daily_claimed,omitempty"`
	GuildID          string                   `json:"guild_id,omitempty"`
	AFKClaimedUnix   int64                    `json:"afk_claimed_unix"`
	ActiveBattleID   string                   `json:"active_battle_id,omitempty"`
	BattleSeed       int64                    `json:"battle_seed,omitempty"`
	BalanceVersion   string                   `json:"balance_version,omitempty"`
	BattleCommands   []BattleCommand          `json:"battle_commands,omitempty"`
	BattleTickApprox int                      `json:"battle_tick_approx,omitempty"`
	UpdatedAt        string                   `json:"updated_at"`
}

type Session struct {
	Token     string    `json:"token"`
	AccountID string    `json:"account_id"`
	CreatedAt time.Time `json:"created_at"`
}

type GuildStub struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Role    string `json:"role"`
	Members int    `json:"members"`
	Cap     int    `json:"cap"`
}

type ArenaStub struct {
	Rank   string `json:"rank"`
	Points int    `json:"points"`
	Rival  string `json:"rival"`
}

type EventStub struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	City   string `json:"city"`
	Status string `json:"status"`
	Tone   string `json:"tone"`
}
